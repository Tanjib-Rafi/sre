terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  default = 123     
}

variable "instance_type" {
  type = number     
  default = "t2.micro"
}

module "ec2_module" {
  source = "./modules/ec2"
  
  instance_type = var.instance_type
  subnet_id     = aws_subnet.main.id  
}

resource "aws_security_group" "sg" {
  name = "broken-sg"

  ingress {
    from_port   = 0       
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "ec2_ip" {
  value = module.ec2_module.public_ip 
}