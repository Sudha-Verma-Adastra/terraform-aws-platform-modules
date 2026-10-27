output "instance_id" {
  description = "EC2 instance ID."
  value       = aws_instance.this.id
}

output "instance_arn" {
  description = "EC2 instance ARN."
  value       = aws_instance.this.arn
}

output "private_ip" {
  description = "Private IPv4 address."
  value       = aws_instance.this.private_ip
}

output "public_ip" {
  description = "Public IPv4 address, if assigned."
  value       = aws_instance.this.public_ip
}

output "security_group_id" {
  description = "Security group ID."
  value       = aws_security_group.this.id
}

output "security_group_name" {
  description = "Security group name."
  value       = aws_security_group.this.name
}
