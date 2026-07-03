# Local state by default so the showcase runs with zero pre-provisioning.
# For team use, switch to an S3 backend (bucket + DynamoDB lock table):
#
# terraform {
#   backend "s3" {
#     bucket         = "showcase-tfstate-<account-id>"
#     key            = "ecs/dev/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "showcase-tf-lock"
#     encrypt        = true
#   }
# }
