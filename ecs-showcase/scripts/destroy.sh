#!/usr/bin/env bash
# Tear down the whole dev stack.
# Usage: AWS_PROFILE=aws-10 TF_VAR_db_password=... ./scripts/destroy.sh
set -euo pipefail

ENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../terraform/environments/dev" && pwd)"
export AWS_REGION="${AWS_REGION:-us-east-1}"

cd "$ENV_DIR"
terraform destroy -input=false -auto-approve -var "image_tag=${IMAGE_TAG:-latest}"
