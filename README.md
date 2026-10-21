# Terraform AWS Platform Modules

A reusable Terraform module library for building secure, consistent, and maintainable AWS infrastructure. The project emphasizes reusable module contracts, secure defaults, automated testing, and troubleshooting documentation.

## Project Goals

- Build reusable AWS infrastructure modules.
- Validate inputs and enforce networking constraints.
- Apply least-privilege IAM and secure storage defaults.
- Test infrastructure logic without deploying AWS resources.
- Automate Terraform formatting, validation, linting, and security checks.
- Document errors, root causes, fixes, and validation results.

## Modules

| Module | Purpose | Status |
|---|---|---|
| `modules/vpc` | Multi-AZ VPC, public/private subnets, route tables, Internet Gateway | 13 native Terraform tests passing |
| `modules/s3-bucket` | Reusable secure S3 storage | In development |
| `modules/iam-role` | Reusable IAM role and policy configuration | In development |

## Repository Structure

```text
.
├── .github/workflows/       # CI workflows
├── docs/                    # Architecture and troubleshooting
├── environments/            # Environment-specific configuration
├── modules/
│   ├── vpc/
│   │   └── tests/           # Native Terraform tests
│   ├── s3-bucket/
│   └── iam-role/
└── examples/                # Example configurations
```

## VPC Module Capabilities

- VPC DNS support and DNS hostnames.
- Multiple public and private subnets across Availability Zones.
- CIDR validation, duplicate detection, and subnet-range checks.
- Public routing through an Internet Gateway.
- Separate private route tables and subnet associations.
- Resource tagging and reusable outputs.
- Native Terraform tests using a mocked AWS provider.

The VPC module does not currently create NAT Gateways, VPC endpoints, security-group rules, or workload resources. Private subnets therefore do not receive outbound internet access through this module by default.

## Local Validation

Run these commands from the repository root:

```bash
terraform -chdir=modules/vpc fmt -check
terraform -chdir=modules/vpc init -backend=false
terraform -chdir=modules/vpc validate
terraform -chdir=modules/vpc test
```

The VPC module's native test suite has passed all 13 tests. These tests use Terraform's test framework and a mocked AWS provider; they do not demonstrate that resources have been deployed or verified in a live AWS account.

## Security Principles

- Least-privilege IAM.
- Encryption and public-access protections where applicable.
- Private networking defaults where appropriate.
- No hardcoded credentials or secrets.
- Automated infrastructure validation and security checks.
- Explicit review of plans, costs, and cleanup before deployment.

## Troubleshooting

See [VPC Troubleshooting Log](docs/vpc-troubleshooting.md) for the errors encountered during development, root-cause analysis, fixes, and validation results.

## Deployment Status

No AWS deployment is claimed as part of the current VPC test milestone. Any future deployment must be reviewed separately, including its Terraform plan, permissions, expected costs, and cleanup strategy.
