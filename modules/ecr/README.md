# ECR Terraform Module

Creates a private Amazon Elastic Container Registry (ECR) repository
for storing container images.

## Features

- Image scanning on push
- Immutable tags by default
- AES256 or customer-managed KMS encryption
- Optional image lifecycle policy
- Configurable image retention
- Resource tagging
- Repository ARN, URL, name and registry ID outputs

## Usage

```hcl
module "ecr" {
  source = "../../modules/ecr"

  repository_name       = "my-application"
  image_tag_mutability  = "IMMUTABLE"
  scan_on_push          = true
  encryption_type       = "AES256"
  create_lifecycle_policy = true
  max_image_count       = 20

  tags = {
    Project     = "example"
    Environment = "dev"
  }
}
