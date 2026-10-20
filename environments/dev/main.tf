provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "../../modules/vpc"

  name                 = var.name
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  tags = {
    Environment = var.environment
    Owner       = "platform-engineering"
  }
}

module "s3_bucket" {
  source = "../../modules/s3-bucket"

  bucket_name = var.bucket_name

  tags = {
    Environment = var.environment
    Owner       = "platform-engineering"
  }
}

module "iam_role" {
  source = "../../modules/iam-role"

  role_name        = var.iam_role_name
  service_principal = "ec2.amazonaws.com"

  tags = {
    Environment = var.environment
    Owner       = "platform-engineering"
  }
}
