variable "cluster_name" {
  description = "The name to use for all cluster resources"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the cluster"
  type        = string
  default     = "t3.micro"
}

variable "min_size" {
  description = "Minimum number of EC2 instances in the ASG"
  type        = number
}

variable "max_size" {
  description = "Maximum number of EC2 instances in the ASG"
  type        = number
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

variable "enable_alb" {
  description = "Whether to enable the Application Load Balancer"
  type        = bool
  default     = true
}

variable "enable_detailed_monitoring" {
  description = "Whether to enable detailed monitoring for EC2 instances"
  type        = bool
  default     = false
}


