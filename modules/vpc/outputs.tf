output "vpc_id" {
  description = "ID of the created VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "IPv4 CIDR block assigned to the VPC."
  value       = aws_vpc.this.cidr_block
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway."
  value       = aws_internet_gateway.this.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs, ordered by the input Availability Zones."
  value       = [for index in range(length(var.availability_zones)) : aws_subnet.public[tostring(index)].id]
}

output "private_subnet_ids" {
  description = "Private subnet IDs, ordered by the input Availability Zones."
  value       = [for index in range(length(var.availability_zones)) : aws_subnet.private[tostring(index)].id]
}

output "public_route_table_id" {
  description = "Route table ID associated with the public subnets."
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "Map of input subnet index to private route table ID."
  value       = { for index, route_table in aws_route_table.private : index => route_table.id }
}

output "availability_zones" {
  description = "Availability Zones used by the module."
  value       = var.availability_zones
}
