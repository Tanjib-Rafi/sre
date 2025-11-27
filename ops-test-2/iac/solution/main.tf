terraform {
  required_version = ">= 1.14"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" # updated version
    }
  }
}

## if not in variables.tf file, define variables here at top
variable "region" {
  type    = string # type was missing
  default = "us-east-1"     
}

variable "instance_type" {
  type = string # type should be string     
  default = "t2.micro"
}

variable "subnet_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

provider "aws" {
  region = var.region
}


module "ec2_module" {
  source = "./modules/ec2"
  
  instance_type = var.instance_type
  subnet_id     = aws_subnet.main.id  
  sg_id         = aws_security_group.sg.id
}

resource "aws_security_group" "sg" {
  name = "fixed-sg"
  description = "Allow SSH only"

  # allow only ssh port
  ingress {
    from_port   = 22       
    to_port     = 22
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

# create a subnet resource
resource "aws_subnet" "main" {
  vpc_id            = var.vpc_id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}


output "ec2_ip" {
  value = module.ec2_module.public_ip 
}