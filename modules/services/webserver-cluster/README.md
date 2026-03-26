# Webserver Cluster Module

This module deploys a webserver cluster with an Auto Scaling Group behind an Application Load Balancer.

## Usage

```hcl
module "webserver_cluster" {
  source = "./modules/services/webserver-cluster"

  cluster_name  = "webservers-prod"
  instance_type = "t2.micro"
  min_size      = 2
  max_size      = 10
  server_port   = 80
  ami_id        = "ami-12345678"
  web_message   = "Hello from production"
}
```

## Inputs

- `cluster_name`: Name for all cluster resources
- `instance_type`: EC2 instance type (default: t2.micro)
- `min_size`: Minimum instances in ASG
- `max_size`: Maximum instances in ASG
- `server_port`: HTTP port (default: 80)
- `ami_id`: AMI ID for instances
- `web_message`: Message displayed on web server (default: "Hello, World")
- `allowed_cidr_blocks`: CIDR blocks for access (default: ["0.0.0.0/0"])
- `availability_zones`: List of AZs for subnets

## Outputs

- `alb_dns_name`: DNS name of the load balancer
- `asg_name`: Name of the Auto Scaling Group