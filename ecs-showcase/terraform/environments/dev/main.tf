terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.tags
  }
}

locals {
  name_prefix = "showcase-${var.environment}"
  tags = {
    Project      = "cloudnative-devops-showcase-ecs"
    Environment  = var.environment
    ManagedBy    = "terraform"
    Orchestrator = "ecs-fargate"
  }
}

module "network" {
  source = "../../modules/network"

  name_prefix          = local.name_prefix
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  single_nat_gateway   = var.single_nat_gateway
  tags                 = local.tags
}

module "ecr" {
  source = "../../modules/ecr"

  name_prefix = local.name_prefix
  tags        = local.tags
}

module "s3" {
  source = "../../modules/s3"

  name_prefix = local.name_prefix
  tags        = local.tags
}

module "rds" {
  source = "../../modules/rds"

  name_prefix         = local.name_prefix
  vpc_id              = module.network.vpc_id
  vpc_cidr            = var.vpc_cidr
  private_subnet_ids  = module.network.private_subnet_ids
  instance_class      = var.db_instance_class
  multi_az            = var.db_multi_az
  db_password         = var.db_password
  deletion_protection = var.db_deletion_protection
  tags                = local.tags
}

module "alb" {
  source = "../../modules/alb"

  name_prefix       = local.name_prefix
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  frontend_port     = var.frontend_port
  tags              = local.tags
}

module "ecs" {
  source = "../../modules/ecs"

  name_prefix               = local.name_prefix
  environment               = var.environment
  aws_region                = var.aws_region
  vpc_id                    = module.network.vpc_id
  private_subnet_ids        = module.network.private_subnet_ids
  assign_public_ip          = var.assign_public_ip
  alb_security_group_id     = module.alb.alb_security_group_id
  frontend_target_group_arn = module.alb.frontend_target_group_arn
  frontend_port             = var.frontend_port

  frontend_image = "${module.ecr.repository_urls["frontend"]}:${var.frontend_image_tag}"
  backend_image  = "${module.ecr.repository_urls["backend"]}:${var.backend_image_tag}"

  frontend_desired_count = var.frontend_desired_count
  backend_desired_count  = var.backend_desired_count

  db_host     = module.rds.address
  db_password = var.db_password

  tags = local.tags
}
