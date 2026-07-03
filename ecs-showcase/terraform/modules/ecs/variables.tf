variable "name_prefix" {
  type = string
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "assign_public_ip" {
  description = "Assign public IPs to task ENIs (true = run tasks in public subnets without NAT)"
  type        = bool
  default     = false
}

variable "alb_security_group_id" {
  type = string
}

variable "frontend_target_group_arn" {
  type = string
}

variable "service_connect_namespace" {
  type    = string
  default = "showcase.local"
}

# Images (ECR repo URL + tag)
variable "frontend_image" {
  type = string
}

variable "backend_image" {
  type = string
}

# Sizing — kept small to stay within the Fargate On-Demand vCPU quota.
variable "frontend_cpu" {
  type    = number
  default = 256
}

variable "frontend_memory" {
  type    = number
  default = 512
}

variable "backend_cpu" {
  type    = number
  default = 256
}

variable "backend_memory" {
  type    = number
  default = 512
}

variable "frontend_port" {
  type    = number
  default = 8080
}

variable "frontend_desired_count" {
  type    = number
  default = 1
}

variable "backend_desired_count" {
  type    = number
  default = 1
}

# Database wiring
variable "db_host" {
  type = string
}

variable "db_name" {
  type    = string
  default = "helloworld"
}

variable "db_username" {
  type    = string
  default = "helloworld"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "log_retention_days" {
  type    = number
  default = 14
}

variable "tags" {
  type    = map(string)
  default = {}
}
