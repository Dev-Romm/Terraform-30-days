provider "aws" {
  region = var.aws_region
}

resource "aws_instance" "firstec2" {
  ami = var.ami_id
  instance_type = var.instance_type
  vpc_security_group_ids = [ aws_security_group.secgroup.id ]

  user_data = <<-EOF
              #!/bin/bash
              echo "${var.web_message}" > index.html
              nohup busybox httpd -f -p ${var.port_number} &
              EOF

  user_data_replace_on_change = true

  tags = {
    Name = var.instance_name
  }
}

resource "aws_security_group" "secgroup" {
  name = var.security_group_name

  ingress {
    from_port = var.port_number
    to_port = var.port_number
    protocol = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }
}

data "aws_instance" "fetchtest" {

  filter {
    name   = "tag:Name"
    values = ["${var.instance_name}"]
  }
}

output "show_fetched" {
  value = data.aws_instance.fetchtest.public_ip
}