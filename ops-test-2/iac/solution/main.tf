terraform {
  required_version = ">= 1.14"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" # updated version
    }
  }
}


provider "aws" {
  region = var.region
}

module "vpc" {
  source = "./modules/vpc"
}

module "ec2_module" {
  source = "./modules/ec2"

  instance_type = var.instance_type
  subnet_id     = module.vpc.subnet_id
  sg_id         = module.vpc.ssh_sg_id
}
