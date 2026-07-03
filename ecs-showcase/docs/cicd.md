# CI/CD

Two GitHub Actions workflows at the repo root (`.github/workflows/`):

| Workflow | Trigger | Does |
| -------- | ------- | ---- |
| **CI** (`ci.yml`) | every push / PR | backend pytest, build both Docker images, `terraform validate` |
| **Deploy** (`deploy.yml`) | after CI succeeds on `main` (or manual) | build+push images to ECR and `terraform apply` the ECS services |

App-only changes never touch infrastructure by hand: you push code, CI gates it,
and Deploy rolls a new ECS task-definition revision. Terraform still runs on
deploy, but the plan is limited to the new image tag + service update — the VPC,
RDS, ALB, IAM and cluster are a no-op diff.

## What backs it

* **Remote state** — S3 bucket `showcase-tfstate-372806410594`
  (`ecs/dev/terraform.tfstate`) + DynamoDB lock table `showcase-tf-lock`, so CI
  and humans share one state. Configured in `terraform/environments/dev/backend.tf`.
* **Auth** — GitHub OIDC, no long-lived AWS keys. The workflow assumes IAM role
  `showcase-github-actions-deploy`, whose trust policy is scoped to this repo
  (`repo:Joseph19820124/cloud-native-devops-showcase-ecs:*`). Permissions =
  `PowerUserAccess` + an inline policy allowing IAM role management scoped to
  `role/showcase-*`.
* **Secrets** — repo secrets `AWS_DEPLOY_ROLE_ARN` and `DB_PASSWORD`.

## Bootstrapping in a fresh account

These exist out-of-band (they can't live in the state they hold):

```bash
# 1. state bucket + lock table
aws s3api create-bucket --bucket showcase-tfstate-<acct> --region us-east-1
aws s3api put-bucket-versioning --bucket showcase-tfstate-<acct> \
  --versioning-configuration Status=Enabled
aws dynamodb create-table --table-name showcase-tf-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST

# 2. GitHub OIDC provider
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 1c58a3a8518e8759bf075b76b750d4f2df264fcd

# 3. deploy role (trust = the OIDC provider, scoped to this repo) + policies
# 4. gh secret set AWS_DEPLOY_ROLE_ARN / DB_PASSWORD
```

## Tightening later

* Restrict the role trust `sub` from `:*` to `:ref:refs/heads/main`.
* Replace `PowerUserAccess` with a least-privilege policy once the resource set
  is stable.
* Move the DB password from a Terraform variable to AWS Secrets Manager and
  reference it via the task definition's `secrets` block.
