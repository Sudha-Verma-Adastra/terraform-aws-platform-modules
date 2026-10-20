variable "aws_region" {
  description = "AWS region for the example."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Name prefix for resources."
  type        = string
  default     = "platform-dev"
}

variable "environment" {
  description = "Environment label."
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "VPC IPv4 CIDR."
  type        = string
  default     = "10.20.0.0/16"
}

variable "availability_zones" {
  description = "Availability Zones for the example."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs."
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs."
  type        = list(string)
  default     = ["10.20.11.0/24", "10.20.12.0/24"]
}

variable "bucket_name" {
  description = "Globally unique name for the platform S3 bucket."
  type        = string
}

variable "iam_role_name" {
  description = "Name of the example IAM service role."
  type        = string
  default     = "platform-dev-example-role"
}