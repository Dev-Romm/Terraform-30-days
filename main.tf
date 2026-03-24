provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "firstec2" {
  ami = "ami-053b0d53c279acc90"
  instance_type = "t3.micro"
  vpc_security_group_ids = [ aws_security_group.secgroup.id ]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF

  user_data_replace_on_change = true

  tags = {
    Name = "my-first-ec2"
  }
}

resource "aws_security_group" "secgroup" {
  name = "my-instance-sg-east1"

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
}