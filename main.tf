terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.26.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.0.1"
    }
  }
  required_version = ">= 1.1.0"

  cloud {
    organization = "srikanth-samatha"

    workspaces {
      name = "github-action"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "random_pet" "sg" {}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web-sg.id]

  user_data = <<-EOF
             #!/bin/bash
              sudo apt-get update -y
              sudo apt install docker.io -y
              sudo apt install docker-compose -y
              
              echo
              git clone https://github.com/srikanthoggari/Snipe-IT.git
              sleep 2m
              cd /snipe-it/
              sudo chmod 777 /snipe-it/
              sed -i 's/44.211.144.174/curl ifconfig.me/g' .env.docker
              sleep 1m
              sudo docker-compose up
              EOF
}

resource "aws_security_group" "web-sg" {
  name = "${random_pet.sg.id}-sg"
  ingress {
    from_port   = 0
    to_port     = 6553
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  // connectivity to ubuntu mirrors is required to run `apt-get update` and `apt-get install apache2`
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "web-address" {
  value = "${aws_instance.web.public_ip}:8000"
}
