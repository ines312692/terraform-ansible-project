terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data sources pour utiliser les ressources existantes
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_subnet" "selected" {
  id = data.aws_subnets.default.ids[0]
}

# Random ID pour noms uniques
resource "random_id" "suffix" {
  byte_length = 4
}

# Security Group
resource "aws_security_group" "web_server" {
  name        = "lab-web-sg-${random_id.suffix.hex}"
  description = "Security group for web servers"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lab-web-sg"
  }
}

# EC2 Instances
resource "aws_instance" "web" {
  count                  = 2
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web_server.id]
  subnet_id              = data.aws_subnet.selected.id
  key_name               = var.vocareum_key_name

  tags = {
    Name        = "lab-web-${count.index + 1}"
    Environment = "learning"
    Ansible     = "managed"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y python3
              EOF
}

