output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "frontend_target_group_arn" {
  value = aws_lb_target_group.frontend.arn
}

output "listener_arn" {
  value = aws_lb_listener.http.arn
}
