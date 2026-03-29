variable "aws_region" {
  description = "The current AWS region"
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  description = "The EC2 instance type"
  type = string
  default = "t3.micro"
}

variable "port_number" {
 description = "The http port number"
 type = number
 default = 80
}

variable "ami_id" {
  description = "The AMI ID for the EC2 instance"
  type        = string
  default     = "ami-053b0d53c279acc90"
}

variable "security_group_name" {
  description = "Name of the security group"
  type        = string
  default     = "my-instance-sg-east1"
}

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "my-first-ec2"
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the instance"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "web_message" {
  description = "Message to display on the web server"
  type        = string
  default     = "Hello, People. This is v1."
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



