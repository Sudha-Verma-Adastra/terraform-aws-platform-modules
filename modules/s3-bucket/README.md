# AWS S3 Bucket Module

A reusable Terraform module for creating S3 buckets with security-focused defaults.

## Features

- Configurable, globally unique bucket name.
- All four S3 Block Public Access settings enabled.
- Default server-side encryption using SSE-S3 (AES256).
- S3 bucket versioning enabled.
- Bucket policy denying requests that use insecure transport.
- Terraform-managed resource tags.
- Input validation for bucket names.

## Security Controls

### Public access protection

The module enables all four public-access-block settings:

- `block_public_acls`
- `block_public_policy`
- `ignore_public_acls`
- `restrict_public_buckets`

These settings reduce the risk of accidental public exposure. Review account-level S3 settings and any applicable organization policies as well.

### Encryption at rest

The module configures default server-side encryption using AES256 (SSE-S3).

This is S3-managed encryption. Customer-managed AWS KMS keys are not configured by this module.

### Versioning

Bucket versioning is enabled to retain versions of objects when they are overwritten or deleted. Versioning alone is not a complete backup strategy; retention, recovery procedures, and lifecycle policies should be designed for the workload.

### Secure transport

The bucket policy denies S3 actions when `aws:SecureTransport` is `false`, enforcing secure transport for requests covered by the policy.

### Naming validation

The `bucket_name` input validation checks:

- Length between 3 and 63 characters.
- Lowercase letters, numbers, dots, and hyphens.
- A letter or number at the beginning and end.
- No consecutive dots.

This is input validation, not a complete guarantee that a name meets every AWS S3 naming restriction or is globally available. AWS remains authoritative for bucket-name acceptance and uniqueness.

## Inputs

| Name | Type | Required | Description |
|---|---|---|---|
| `bucket_name` | `string` | Yes | Globally unique S3 bucket name |
| `tags` | `map(string)` | No | Additional bucket tags; defaults to `{}` |

## Outputs

| Name | Description |
|---|---|
| `bucket_id` | S3 bucket name/ID |
| `bucket_arn` | S3 bucket ARN |
| `bucket_region` | Region reported by the AWS provider |

## Testing

Run the following commands from the repository root:

```bash
terraform -chdir=modules/s3-bucket fmt -check
terraform -chdir=modules/s3-bucket init -backend=false
terraform -chdir=modules/s3-bucket validate
terraform -chdir=modules/s3-bucket test
```

### Native test coverage

The current test suite contains eight test runs covering:

1. Valid bucket name.
2. All four public-access-block settings.
3. Default AES256 encryption.
4. Bucket versioning enabled.
5. Insecure transport denied by the bucket policy.
6. Rejection of a bucket name that is too short.
7. Rejection of uppercase characters.
8. Rejection of consecutive dots.

The tests use Terraform's native test framework and a mocked AWS provider. They validate configuration without deploying resources to AWS.

## Current scope and limitations

This module does not currently configure:

- Customer-managed KMS keys.
- Lifecycle or noncurrent-version expiration policies.
- Access logging.
- Replication or cross-region disaster recovery.
- Object Lock.
- Workload-specific IAM access policies.

Add these features only when required by the security, compliance, and recovery requirements of the intended workload.

## Troubleshooting

See [`../../docs/s3-bucket-troubleshooting.md`](../../docs/s3-bucket-troubleshooting.md) for errors encountered during test development, root causes, fixes, and validation notes.
