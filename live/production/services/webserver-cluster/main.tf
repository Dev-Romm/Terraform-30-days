provider "aws" {
  region = "us-east-1"
}

module "webserver_cluster" {
  source = "../../../../modules/services/webserver-cluster"

  cluster_name  = "webservers-production"
  instance_type = "t2.micro"
  min_size      = 4
  max_size      = 10
  ami_id        = "ami-053b0d53c279acc90"
  web_message   = "Hello from production environment"
}

output "alb_dns_name" {
  value = module.webserver_cluster.alb_dns_name
}