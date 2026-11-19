output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "IP range of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "private_subnet_ids" {
  description = "IDs of the two private subnets"
  value       = aws_subnet.private[*].id
}

output "private_route_table_id" {
  description = "ID of the route table used by the private subnets"
  value       = aws_route_table.private.id
}

output "nat_gateway_id" {
  description = "ID of the managed NAT gateway, or an empty string when the NAT instance is used"
  value       = var.create_nat_gateway ? aws_nat_gateway.main[0].id : ""
}
