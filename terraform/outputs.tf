output "vpc_id" {
  value = aws_vpc.main.id
}

output "web_server_ips" {
  value = aws_instance.web[*].public_ip
}

output "web_server_private_ips" {
  value = aws_instance.web[*].private_ip
}

output "s3_bucket_name" {
  value = aws_s3_bucket.logs.id
}