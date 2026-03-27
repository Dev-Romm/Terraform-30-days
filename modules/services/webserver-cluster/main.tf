locals {
  # Centralize conditional logic for ALB resources
  alb_count = var.enable_alb ? 1 : 0
  
  # Create a map of availability zones for potential for_each usage
  availability_zone_map = {
    for az in var.availability_zones : az => az
  }
  
  # Conditional monitoring settings
  monitoring_enabled = var.enable_detailed_monitoring
}

resource "aws_launch_template" "example" {
  name         = "${var.cluster_name}-lt"
  image_id      = var.ami_id
  instance_type = var.instance_type

  monitoring {
    enabled = local.monitoring_enabled
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

resource "aws_autoscaling_group" "example" {
  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }
  vpc_zone_identifier = data.aws_subnets.default.ids

  target_group_arns = local.alb_count > 0 ? [aws_lb_target_group.example[0].arn] : []
  health_check_type = local.alb_count > 0 ? "ELB" : "EC2"

  min_size = var.min_size
  max_size = var.max_size

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-asg"
    propagate_at_launch = true
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
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
  subnets            = data.aws_subnets.default.ids
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
  vpc_id      = data.aws_vpc.default.id
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

resource "aws_lb_target_group" "example" {
  count = local.alb_count
  
  name     = "${var.cluster_name}-tg"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

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

resource "aws_lb_listener_rule" "example" {
  count = local.alb_count
  
  listener_arn = aws_lb_listener.http[0].arn
  priority     = 100
  condition {
    path_pattern {
      values = ["*"]
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example[0].arn
  }
}
