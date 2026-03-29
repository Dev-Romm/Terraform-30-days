output "alb_dns_name" {
  value       = local.alb_count > 0 ? aws_lb.example[0].dns_name : null
  description = "The domain name of the load balancer"
}

output "asg_name" {
  value       = local.active_asg_name
  description = "The name of the active Auto Scaling Group"
}

# GOTCHA 3 SOLUTION: Granular outputs for specific resources
# WRONG approach: Callers should NOT do: depends_on = [module.webserver_cluster]
# This forces Terraform to recreate the ENTIRE module when dependencies change
# CORRECT approach: Expose granular outputs so callers depend only on what they need
output "security_group_id" {
  value       = aws_security_group.alb.id
  description = "The ID of the ALB security group. Use this output for depends_on instead of the entire module"
}

output "launch_template_id" {
  value       = aws_launch_template.example.id
  description = "The ID of the launch template used by the ASG"
}

output "launch_template_latest_version" {
  value       = aws_launch_template.example.latest_version
  description = "The latest version number of the launch template"
}

output "alb_arn" {
  value       = local.alb_count > 0 ? aws_lb.example[0].arn : null
  description = "The ARN of the load balancer"
}

output "target_group_arn" {
  value       = local.alb_count > 0 ? (var.active_environment == "blue" ? aws_lb_target_group.blue[0].arn : aws_lb_target_group.green[0].arn) : null
  description = "The ARN of the active target group"
}

# Use a for expression to create a useful map of availability zones
output "availability_zones_map" {
  value = {
    for idx, az in var.availability_zones : 
    "zone_${idx}" => az
  }
  description = "A map of availability zones indexed by zone_0, zone_1, etc."
}

output "alarm_arn" {
  value       = var.enable_detailed_monitoring ? aws_cloudwatch_metric_alarm.high_cpu[0].arn : null
  description = "The ARN of the CloudWatch alarm for high CPU"
}

output "vpc_id" {
  value       = local.vpc_id
  description = "The ID of the VPC"
}
 

output "route53_record_name" {
  value       = var.create_dns_record ? aws_route53_record.alb[0].name : null
  description = "The name of the Route53 DNS record"
}