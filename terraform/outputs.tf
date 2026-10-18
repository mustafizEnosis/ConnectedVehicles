# Networking outputs
output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.main.id
}

output "nat_gateway_ids" {
  value = aws_nat_gateway.main[*].id
}

output "s3_endpoint_id" {
  value = aws_vpc_endpoint.s3.id
}

# Security group outputs
output "ecs_tasks_security_group_id" {
  value = aws_security_group.ecs_tasks.id
}

output "msk_security_group_id" {
  value = aws_security_group.msk.id
}

output "mq_security_group_id" {
  value = aws_security_group.mq.id
}