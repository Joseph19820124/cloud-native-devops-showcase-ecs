variable "environment" {
  type    = string
  default = "dev"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

# NOTE: 10.0.0.0/16 is already used by another VPC in this account; the ECS
# stack gets its own range to avoid confusion.
variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.20.0.0/24", "10.20.1.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.20.10.0/24", "10.20.11.0/24"]
}

variable "single_nat_gateway" {
  type    = bool
  default = true
}

# When true, tasks run in private subnets and reach ECR/RDS through the NAT
# gateway (default, production-like). Set false + assign_public_ip=true to skip
# the NAT gateway for a cheaper throwaway stack.
variable "assign_public_ip" {
  type    = bool
  default = false
}

variable "frontend_port" {
  type    = number
  default = 8080
}

# Per-service image tags so only the service whose code changed gets a new task
# revision. CI/CD sets each to the SHA of the last commit that touched that
# service's app dir (see .github/workflows). Unchanged service keeps its tag ->
# Terraform no-op -> it does not roll.
variable "backend_image_tag" {
  description = "Image tag (commit SHA) for the backend service"
  type        = string
  default     = "latest"
}

variable "frontend_image_tag" {
  description = "Image tag (commit SHA) for the frontend service"
  type        = string
  default     = "latest"
}

variable "frontend_desired_count" {
  type    = number
  default = 1
}

variable "backend_desired_count" {
  type    = number
  default = 1
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "db_multi_az" {
  type    = bool
  default = false
}

variable "db_deletion_protection" {
  type    = bool
  default = false
}

variable "db_password" {
  type      = string
  sensitive = true
}
