output "vpc_id" {
  value = data.aws_vpc.default.id
}

output "subnet_id" {
  value = data.aws_subnet.selected.id
}

output "web_server_ips" {
  value = aws_instance.web[*].public_ip
}

output "web_server_private_ips" {
  value = aws_instance.web[*].private_ip
}

output "security_group_id" {
  value = aws_security_group.web_server.id
}