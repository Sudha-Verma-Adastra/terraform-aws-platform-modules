# Terraform AWS Platform Modules

A reusable Terraform module library for building secure, consistent,
and maintainable AWS infrastructure.

## Objectives

- Reusable and composable Terraform modules
- Secure AWS networking defaults
- Least-privilege IAM
- Encrypted S3 storage and public-access protection
- Input validation and explicit module contracts
- Automated formatting, validation, linting, and security checks
- Environment-specific composition and documentation

## Modules

| Module | Purpose |
|---|---|
| vpc | VPC networking and subnet design |
| s3-bucket | Secure S3 storage |
| iam-role | Reusable IAM role and policy configuration |

## Repository Structure

- `modules/` - Reusable Terraform modules
- `examples/` - Example module compositions
- `environments/` - Environment-specific configuration
- `tests/` - Module test cases
- `docs/` - Architecture and troubleshooting documentation
- `.github/workflows/` - CI workflows

## Security Principles

- Least privilege
- Encryption at rest and in transit where applicable
- Private networking by default where appropriate
- No hardcoded credentials or secrets
- Automated infrastructure security checks

## Deployment

Cloud deployment instructions will be added after module development,
local validation, and security review.
