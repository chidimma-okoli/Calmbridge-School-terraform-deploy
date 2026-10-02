output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.cally_vpc.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.cally_public_subnet.id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = aws_subnet.cally_private_subnet.id
}

output "database_subnet_id" {
  description = "ID of the first database subnet"
  value       = aws_subnet.cally_database_subnet.id
}

output "frontend_public_ip" {
  description = "Public IP of the frontend EC2"
  value       = aws_instance.frontend_server.public_ip
}

output "backend_private_ip" {
  description = "Private IP of the backend EC2"
  value       = aws_instance.backend_server.private_ip
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.db_server.endpoint
}