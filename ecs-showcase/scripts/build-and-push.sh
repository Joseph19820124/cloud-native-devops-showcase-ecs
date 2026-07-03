#!/usr/bin/env bash
# Build the frontend and backend images and push them to ECR.
# Usage: FRONTEND_REPO=... BACKEND_REPO=... TAG=... ./scripts/build-and-push.sh
set -euo pipefail

REGION="${AWS_REGION:-us-east-1}"
TAG="${TAG:-latest}"
: "${FRONTEND_REPO:?set FRONTEND_REPO to the ECR repo URL}"
: "${BACKEND_REPO:?set BACKEND_REPO to the ECR repo URL}"

REGISTRY="${FRONTEND_REPO%%/*}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo ">> Logging in to ECR registry $REGISTRY"
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$REGISTRY"

echo ">> Building backend ($BACKEND_REPO:$TAG)"
docker build --platform linux/amd64 -t "$BACKEND_REPO:$TAG" "$ROOT/app/backend"
docker push "$BACKEND_REPO:$TAG"

echo ">> Building frontend ($FRONTEND_REPO:$TAG)"
docker build --platform linux/amd64 -t "$FRONTEND_REPO:$TAG" "$ROOT/app/frontend"
docker push "$FRONTEND_REPO:$TAG"

echo ">> Pushed images with tag $TAG"
