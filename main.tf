provider "aws" {
  region = var.aws_region
}

module "webserver_cluster" {
  source = "./modules/services/webserver-cluster"

  cluster_name  = "terraform-asg-example"
  server_port   = var.port_number
  ami_id        = var.ami_id
  web_message   = var.web_message
  allowed_cidr_blocks = var.allowed_cidr_blocks
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1f"]
  enable_alb = true
  enable_detailed_monitoring = false
  environment = "dev"
  create_dns_record = false
  use_existing_vpc = false
  domain_name = ""
}

output "alb_dns_name" {
  value = module.webserver_cluster.alb_dns_name
  description = "The domain name of the load balancer"
}