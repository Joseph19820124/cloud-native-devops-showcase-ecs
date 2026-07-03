output "alb_url" {
  description = "Public URL of the application"
  value       = "http://${module.alb.alb_dns_name}"
}

output "ecr_repository_urls" {
  value = module.ecr.repository_urls
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

output "rds_endpoint" {
  value = module.rds.endpoint
}
