output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_id" {
  value = aws_subnet.public.id
}

output "ssh_sg_id" {
  value = aws_security_group.ssh.id
}
