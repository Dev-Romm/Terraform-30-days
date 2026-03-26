provider "aws" {
  region = "us-east-1"
}

module "webserver_cluster" {
  source = "../../../../modules/services/webserver-cluster"

  cluster_name  = "webservers-dev"
  instance_type = "t3.micro"
  min_size      = 2
  max_size      = 4
  server_port   = 80
  ami_id        = "ami-053b0d53c279acc90"
  web_message   = "Hello from dev environment"
}

output "alb_dns_name" {
  value = module.webserver_cluster.alb_dns_name
}