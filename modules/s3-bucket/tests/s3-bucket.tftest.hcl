mock_provider "aws" {
  override_during = plan

  mock_resource "aws_s3_bucket" {
    defaults = {
      id     = "test-platform-bucket"
      arn    = "arn:aws:s3:::test-platform-bucket"
      region = "us-east-1"
    }
  }
}

run "valid_bucket_name" {
  command = plan

  variables {
    bucket_name = "test-platform-bucket"
  }

  assert {
    condition     = aws_s3_bucket.this.bucket == "test-platform-bucket"
    error_message = "The S3 bucket must use the configured bucket name."
  }
}

run "block_all_public_access" {
  command = plan

  variables {
    bucket_name = "test-platform-bucket"
  }

  assert {
    condition = (
      aws_s3_bucket_public_access_block.this.block_public_acls &&
      aws_s3_bucket_public_access_block.this.block_public_policy &&
      aws_s3_bucket_public_access_block.this.ignore_public_acls &&
      aws_s3_bucket_public_access_block.this.restrict_public_buckets
    )
    error_message = "All four S3 public access block settings must be enabled."
  }
}

run "enable_default_encryption" {
  command = plan

  variables {
    bucket_name = "test-platform-bucket"
  }
  assert {
    condition = alltrue([
      for rule in aws_s3_bucket_server_side_encryption_configuration.this.rule :
      rule.apply_server_side_encryption_by_default[0].sse_algorithm == "AES256"
    ])
    error_message = "S3 default server-side encryption must use AES256."
  }
}

run "enable_bucket_versioning" {
  command = plan

  variables {
    bucket_name = "test-platform-bucket"
  }

  assert {
    condition = (
      aws_s3_bucket_versioning.this.versioning_configuration[0].status == "Enabled"
    )
    error_message = "S3 bucket versioning must be enabled."
  }
}

run "deny_insecure_transport" {
  command = plan

  variables {
    bucket_name = "test-platform-bucket"
  }

  assert {
    condition = (
      jsondecode(aws_s3_bucket_policy.tls_only.policy)
      .Statement[0].Effect == "Deny"
    )
    error_message = "The transport security policy must explicitly deny insecure requests."
  }

  assert {
    condition = (
      jsondecode(aws_s3_bucket_policy.tls_only.policy)
      .Statement[0].Condition.Bool["aws:SecureTransport"] == "false"
    )
    error_message = "The policy must deny requests when aws:SecureTransport is false."
  }
}

run "reject_too_short_bucket_name" {
  command = plan

  variables {
    bucket_name = "ab"
  }

  expect_failures = [var.bucket_name]
}

run "reject_uppercase_bucket_name" {
  command = plan

  variables {
    bucket_name = "Test-platform-bucket"
  }

  expect_failures = [var.bucket_name]
}

run "reject_bucket_name_with_double_dots" {
  command = plan

  variables {
    bucket_name = "test..platform-bucket"
  }

  expect_failures = [var.bucket_name]
}
