variable "instance_type" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "sg_id" {
  type = string
}

variable "ami" {
  type    = string
  default = "ami-0c55b159cbfafe1f0"
}

variable "name" {
  type    = string
  default = "my-ec2"
}
