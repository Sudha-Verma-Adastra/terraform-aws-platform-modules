output "vpc_id" {
  description = "VPC ID."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs."
  value       = module.vpc.private_subnet_ids
}

output "s3_bucket_name" {
  description = "Name of the platform S3 bucket."
  value       = module.s3_bucket.bucket_id
}

output "s3_bucket_arn" {
  description = "ARN of the platform S3 bucket."
  value       = module.s3_bucket.bucket_arn
}

output "iam_role_arn" {
  description = "ARN of the example IAM role."
  value       = module.iam_role.role_arn
}