#!/usr/bin/env bash
# End-to-end deploy: provision ECR+network, build & push images, then apply the
# rest of the stack (RDS, ALB, ECS Fargate services).
#
# Usage:
#   AWS_PROFILE=aws-10 TF_VAR_db_password=... ./scripts/deploy.sh
set -euo pipefail

REGION="${AWS_REGION:-us-east-1}"
ENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../terraform/environments/dev" && pwd)"
TAG="${IMAGE_TAG:-$(date +%Y%m%d)-$(git rev-parse --short HEAD 2>/dev/null || echo local)}"
export AWS_REGION="$REGION"

cd "$ENV_DIR"
echo "== terraform init =="
terraform init -input=false

echo "== phase 1: ECR + network =="
terraform apply -input=false -auto-approve \
  -target=module.ecr -target=module.network

FRONTEND_REPO=$(terraform output -json ecr_repository_urls | python3 -c 'import sys,json;print(json.load(sys.stdin)["frontend"])')
BACKEND_REPO=$(terraform output -json ecr_repository_urls | python3 -c 'import sys,json;print(json.load(sys.stdin)["backend"])')

echo "== phase 2: build & push images (tag=$TAG) =="
FRONTEND_REPO="$FRONTEND_REPO" BACKEND_REPO="$BACKEND_REPO" TAG="$TAG" \
  "$(dirname "${BASH_SOURCE[0]}")/build-and-push.sh"

echo "== phase 3: full apply (RDS + ALB + ECS) =="
terraform apply -input=false -auto-approve -var "image_tag=$TAG"

echo
terraform output alb_url
echo "Give the ECS services a minute to reach steady state, then curl the URL above."
