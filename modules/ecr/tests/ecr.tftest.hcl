mock_provider "aws" {}

run "creates_secure_ecr_repository" {
  command = plan

  variables {
    repository_name = "test-zero-trust-app"

    tags = {
      Environment = "test"
    }
  }

  assert {
    condition     = aws_ecr_repository.this.image_tag_mutability == "IMMUTABLE"
    error_message = "Repository tags must be immutable by default."
  }

  assert {
    condition     = aws_ecr_repository.this.image_scanning_configuration[0].scan_on_push
    error_message = "Image scanning on push must be enabled by default."
  }

  assert {
    condition     = aws_ecr_repository.this.encryption_configuration[0].encryption_type == "AES256"
    error_message = "Repository must use AES256 encryption by default."
  }

  assert {
    condition     = aws_ecr_repository.this.force_delete == false
    error_message = "Repository deletion must not force-delete stored images."
  }

  assert {
    condition     = aws_ecr_lifecycle_policy.this[0].repository == aws_ecr_repository.this.name
    error_message = "Lifecycle policy must target the created repository."
  }
}

run "supports_disabled_lifecycle_policy" {
  command = plan

  variables {
    repository_name         = "test-no-lifecycle"
    create_lifecycle_policy = false
  }

  assert {
    condition     = length(aws_ecr_lifecycle_policy.this) == 0
    error_message = "Lifecycle policy should not be created when disabled."
  }
}

run "rejects_invalid_repository_name" {
  command = plan

  variables {
    repository_name = "INVALID REPOSITORY NAME"
  }

  expect_failures = [
    var.repository_name
  ]
}
