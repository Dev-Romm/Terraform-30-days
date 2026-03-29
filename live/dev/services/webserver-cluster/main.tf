provider "aws" {
  region = "us-east-1"
}

module "webserver_cluster" {
  source = "file:///D:/Projects/Terraform%2030%20Days/Day%203%20Deploying%20Your%20First%20Server%20with%20Terraform/terraform/modules/services/webserver-cluster"

  cluster_name  = "web-dev"
  server_port   = 80
  ami_id        = "ami-053b0d53c279acc90"
  web_message   = "Hello again, from dev environment. This is v2."
  enable_alb    = true
  enable_detailed_monitoring = false
  environment = "dev"
  create_dns_record = false
  use_existing_vpc = false
  domain_name = ""
  active_environment = "blue"
}

output "alb_dns_name" {
  value = module.webserver_cluster.alb_dns_name
}

output "availability_zones_map" {
  value = module.webserver_cluster.availability_zones_map
}

output "vpc_id" {
  value = module.webserver_cluster.vpc_id
}