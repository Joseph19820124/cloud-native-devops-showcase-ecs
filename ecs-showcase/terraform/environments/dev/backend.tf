# Remote state in S3 with DynamoDB locking, so CI/CD and humans share one state.
# The bucket + lock table are created out-of-band (see docs/cicd.md); they must
# exist before `terraform init`.
terraform {
  backend "s3" {
    bucket         = "showcase-tfstate-372806410594"
    key            = "ecs/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "showcase-tf-lock"
    encrypt        = true
  }
}
