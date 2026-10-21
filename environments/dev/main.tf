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

  role_name         = var.iam_role_name
  service_principal = "ec2.amazonaws.com"

  tags = {
    Environment = var.environment
    Owner       = "platform-engineering"
  }
}

module "eks" {
  source = "../../modules/eks"

  cluster_name    = var.eks_cluster_name
  cluster_version = var.eks_cluster_version

  # Reuse private subnets spanning at least two Availability Zones.
  cluster_subnet_ids = module.vpc.private_subnet_ids
  node_subnet_ids    = module.vpc.private_subnet_ids

  endpoint_private_access = true
  endpoint_public_access  = false

  node_group_name = "workers"
  instance_types  = ["t3.medium"]
  capacity_type   = "ON_DEMAND"

  min_size     = 1
  desired_size = 2
  max_size     = 3
  disk_size    = 20

  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
    Project     = "terraform-aws-platform-modules"
  }
}
