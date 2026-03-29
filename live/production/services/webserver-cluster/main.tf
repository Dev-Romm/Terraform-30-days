provider "aws" {
  region = "us-east-1"
}

module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"

  cluster_name  = "webservers-production"
  server_port   = 80
  ami_id        = "ami-053b0d53c279acc90"
  web_message   = "Hello from production environment"
  enable_alb    = true
  enable_detailed_monitoring = true
  environment = "production"
  create_dns_record = true
  use_existing_vpc = false
  domain_name = "example.com"
}

output "alb_dns_name" {
  value = module.webserver_cluster.alb_dns_name
}