variable "cluster_name" {
  description = "The name to use for all cluster resources"
  type        = string
}

variable "server_port" {
  description = "Port the server uses for HTTP"
  type        = number
  default     = 80
}

variable "ami_id" {
  description = "The AMI ID for the EC2 instances"
  type        = string
}

variable "web_message" {
  description = "Message to display on the web server"
  type        = string
  default     = "Hello, World"
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the load balancer"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "availability_zones" {
  description = "List of availability zones for subnets"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1f"]
}

variable "environment" {
  description = "Deployment environment: dev, staging, or production"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

variable "enable_alb" {
  description = "Whether to enable the Application Load Balancer"
  type        = bool
  default     = true
}

variable "active_environment" {
  description = "Which environment is currently active: blue or green"
  type        = string
  default     = "blue"

  validation {
    condition     = contains(["blue", "green"], var.active_environment)
    error_message = "Active environment must be blue or green."
  }
}

variable "enable_detailed_monitoring" {
  description = "Whether to enable detailed monitoring for EC2 instances"
  type        = bool
  default     = false
}

variable "create_dns_record" {
  description = "Whether to create a Route53 DNS record for the ALB"
  type        = bool
  default     = false
}

variable "use_existing_vpc" {
  type    = bool
  default = false
}

variable "domain_name" {
  description = "Domain name for Route53 record"
  type        = string
  default     = ""
}


