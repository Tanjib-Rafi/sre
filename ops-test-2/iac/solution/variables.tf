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