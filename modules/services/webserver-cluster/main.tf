locals {
  # Environment-aware settings
  is_production = var.environment == "production"
  
  instance_type      = local.is_production ? "t3.medium" : "t3.micro"
  min_size           = local.is_production ? 3 : 1
  max_size           = local.is_production ? 10 : 3
  enable_monitoring  = local.is_production
  deletion_policy    = local.is_production ? "Retain" : "Delete"
  
  # Centralize conditional logic for ALB resources
  alb_count = var.enable_alb ? 1 : 0
  
  # Create a map of availability zones for potential for_each usage
  availability_zone_map = {
    for az in var.availability_zones : az => az
  }
  
  # Blue/Green deployment settings
  monitoring_enabled = var.enable_detailed_monitoring
  
  # Blue/Green deployment settings
  blue_min_size  = var.active_environment == "blue" ? local.min_size : 0
  green_min_size = var.active_environment == "green" ? local.min_size : 0
  
  # Active ASG name for monitoring
  active_asg_name = var.active_environment == "blue" ? aws_autoscaling_group.blue.name : aws_autoscaling_group.green.name
  
  # VPC selection
  vpc_id = var.use_existing_vpc ? data.aws_vpc.existing[0].id : aws_vpc.new[0].id
}

data "aws_vpc" "existing" {
  count = var.use_existing_vpc ? 1 : 0
  tags = {
    Name = "existing-vpc"
  }
}

resource "aws_vpc" "new" {
  count      = var.use_existing_vpc ? 0 : 1
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "new" {
  count  = var.use_existing_vpc ? 0 : 1
  vpc_id = aws_vpc.new[0].id
}

resource "aws_subnet" "new" {
  count = var.use_existing_vpc ? 0 : length(var.availability_zones)

  vpc_id            = aws_vpc.new[0].id
  cidr_block        = cidrsubnet(aws_vpc.new[0].cidr_block, 8, count.index + 1)
  availability_zone = var.availability_zones[count.index]
  map_public_ip_on_launch = true
}

resource "aws_route_table" "new" {
  count  = var.use_existing_vpc ? 0 : 1
  vpc_id = aws_vpc.new[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.new[0].id
  }
}

resource "aws_route_table_association" "new" {
  count = var.use_existing_vpc ? 0 : length(var.availability_zones)

  subnet_id      = aws_subnet.new[count.index].id
  route_table_id = aws_route_table.new[0].id
}

resource "aws_launch_template" "example" {
  name_prefix   = "${var.cluster_name}-lt"
  image_id      = var.ami_id
  instance_type = local.instance_type

  monitoring {
    enabled = local.enable_monitoring
  }

  vpc_security_group_ids = [aws_security_group.alb.id]

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    server_port = var.server_port
    web_message = var.web_message
  }))


  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "blue" {
  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }
  vpc_zone_identifier = var.use_existing_vpc ? data.aws_subnets.default.ids : aws_subnet.new[*].id

  target_group_arns = local.alb_count > 0 ? [aws_lb_target_group.blue[0].arn] : []
  health_check_type = local.alb_count > 0 ? "ELB" : "EC2"

  min_size = local.blue_min_size
  max_size = local.max_size

  name_prefix = "${var.cluster_name}-blue-asg"

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-blue-asg"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "green" {
  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }
  vpc_zone_identifier = var.use_existing_vpc ? data.aws_subnets.default.ids : aws_subnet.new[*].id

  target_group_arns = local.alb_count > 0 ? [aws_lb_target_group.green[0].arn] : []
  health_check_type = local.alb_count > 0 ? "ELB" : "EC2"

  min_size = local.green_min_size
  max_size = local.max_size

  name_prefix = "${var.cluster_name}-green-asg"

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-green-asg"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  count = var.enable_detailed_monitoring ? 1 : 0

  alarm_name          = "${var.cluster_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "CPU utilization exceeded 80%"

  dimensions = {
    AutoScalingGroupName = local.active_asg_name
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }
  filter {
    name   = "availability-zone"
    values = var.availability_zones
  }
}

resource "aws_lb" "example" {
  count = local.alb_count
  
  name               = "${var.cluster_name}-alb"
  load_balancer_type = "application"
  subnets            = var.use_existing_vpc ? data.aws_subnets.default.ids : aws_subnet.new[*].id
  security_groups    = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  count = local.alb_count
  
  load_balancer_arn = aws_lb.example[0].arn
  port              = var.server_port
  protocol          = "HTTP"
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

resource "aws_security_group" "alb" {
  name_prefix = "${var.cluster_name}-alb-"
  description = "Security group for ${var.cluster_name} ALB"
  vpc_id      = local.vpc_id
}

# GOTCHA 2 SOLUTION: Use separate resources instead of inline blocks
# This allows module callers to add/modify rules without modifying the module
# Example of what NOT to do: mixing inline ingress blocks with aws_security_group_rule resources
resource "aws_security_group_rule" "alb_http_inbound" {
  for_each = toset(var.allowed_cidr_blocks)
  
  type              = "ingress"
  from_port         = var.server_port
  to_port           = var.server_port
  protocol          = "tcp"
  cidr_blocks       = [each.value]
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP traffic on port ${var.server_port} from ${each.value}"
}

resource "aws_security_group_rule" "alb_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "Allow all outbound traffic"
}

resource "aws_lb_target_group" "blue" {
  count = local.alb_count
  
  name     = "${var.cluster_name}-blue-tg"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = local.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group" "green" {
  count = local.alb_count
  
  name     = "${var.cluster_name}-green-tg"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = local.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "blue_green" {
  count = local.alb_count
  
  listener_arn = aws_lb_listener.http[0].arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = var.active_environment == "blue" ? aws_lb_target_group.blue[0].arn : aws_lb_target_group.green[0].arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

data "aws_route53_zone" "primary" {
  count = var.create_dns_record ? 1 : 0
  name  = var.domain_name
}

resource "aws_route53_record" "alb" {
  count = var.create_dns_record ? 1 : 0

  zone_id = data.aws_route53_zone.primary[0].zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.example[0].dns_name
    zone_id                = aws_lb.example[0].zone_id
    evaluate_target_health = true
  }
}
