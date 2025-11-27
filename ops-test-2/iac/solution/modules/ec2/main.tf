## if not in variables.tf file, define variables here at top

variable "instance_type" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "sg_id" {
  type = string
}


resource "aws_instance" "vm" {
  ami           = "ami-0c55b159cbfafe1f0"  # Valid Ubuntu AMI  
  instance_type = var.instance_type

  vpc_security_group_ids = [var.sg_id]  
}

output "public_dns" {
  value = aws_instance.vm.public_dns
}

# create the missing output for public_ip
output "public_ip" {
  value = aws_instance.vm.public_ip
}
