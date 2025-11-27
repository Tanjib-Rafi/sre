resource "aws_instance" "vm" {
  ami           = "ami-123456"   
  instance_type = var.instance_type

  vpc_security_group_ids = [var.sg_id]  
}

output "public_dns" {
  value = aws_instance.vm.public_dns
}