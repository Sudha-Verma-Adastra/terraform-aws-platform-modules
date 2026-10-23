# Terraform AWS IAM Role Module

## Overview

This module creates reusable AWS IAM roles using Terraform. It supports two trust models:

- **Service trust:** Allows an AWS service, such as Lambda, to assume the IAM role.
- **OIDC trust:** Allows an authenticated workload to assume the IAM role using an OpenID Connect (OIDC) identity provider, such as an Amazon EKS service account using IAM Roles for Service Accounts (IRSA).

The module also supports attaching AWS managed IAM policies, defining an optional inline policy, and applying custom tags.

## Features

- Reusable IAM role creation
- Service-principal and OIDC-based trust policies
- Restricted OIDC subject and audience conditions
- Optional AWS managed policy attachments
- Optional inline IAM policy
- Custom tags with a default `ManagedBy = Terraform` tag
- Input validation and Terraform tests

## Requirements

| Requirement | Version |
|---|---|
| Terraform | `>= 1.6.0` |
| AWS provider | `>= 5.0, < 7.0` |

The AWS provider must be configured by the root module or calling environment.

## Usage

### 1. Service trust

Use service trust when an AWS service needs permission to assume the role.

```hcl
module "lambda_execution_role" {
  source = "../../modules/iam-role"

  role_name        = "example-lambda-execution-role"
  service_principal = "lambda.amazonaws.com"

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]

  inline_policy_json = null

  tags = {
    Environment = "dev"
    Project     = "example"
  }
}
```

The resulting trust policy allows the configured AWS service to call `sts:AssumeRole`.

### 2. OIDC trust for an EKS service account

Use OIDC trust when a Kubernetes workload needs AWS permissions without storing long-lived AWS access keys in the workload.

Example for the AWS Load Balancer Controller:

```hcl
module "aws_load_balancer_controller_role" {
  source = "../../modules/iam-role"

  role_name = "aws-load-balancer-controller"

  trust_type = "oidc"

  oidc_provider_arn = var.eks_oidc_provider_arn
  oidc_issuer_url   = var.eks_oidc_issuer_url

  oidc_subject   = "system:serviceaccount:kube-system:aws-load-balancer-controller"
  oidc_audience  = "sts.amazonaws.com"

  managed_policy_arns = []
  inline_policy_json  = null

  tags = {
    Environment = "dev"
    Project     = "aws-zero-trust-web-platform"
  }
}
```

The example assumes that the EKS cluster's OIDC provider has already been registered in IAM and that the supplied ARN and issuer URL correspond to that provider.

Define the provider inputs in the calling environment:

```hcl
variable "eks_oidc_provider_arn" {
  description = "ARN of the IAM OIDC provider associated with the EKS cluster."
  type        = string
}

variable "eks_oidc_issuer_url" {
  description = "HTTPS OIDC issuer URL of the EKS cluster."
  type        = string
}
```

Supply the actual values from the target EKS cluster. Do not substitute placeholder values when deploying.

**Important:** This module creates the IAM role and its trust policy. It does not, by itself, create the EKS OIDC provider, Kubernetes service account, Helm release, or AWS Load Balancer Controller deployment.

## Input variables

| Variable | Type | Default | Description |
|---|---|---|---|
| `role_name` | `string` | Required | Name of the IAM role |
| `service_principal` | `string` | Required | AWS service principal for service trust |
| `trust_type` | `string` | `"service"` | Trust model: `service` or `oidc` |
| `oidc_provider_arn` | `string` | `null` | IAM OIDC provider ARN for OIDC trust |
| `oidc_issuer_url` | `string` | `null` | HTTPS issuer URL of the OIDC provider |
| `oidc_subject` | `string` | `null` | Exact OIDC subject permitted to assume the role |
| `oidc_audience` | `string` | `"sts.amazonaws.com"` | Expected OIDC audience |
| `managed_policy_arns` | `list(string)` | Required | AWS managed policy ARNs to attach |
| `inline_policy_json` | `string` | Required | Optional inline policy JSON; use `null` to omit |
| `tags` | `map(string)` | Required | Additional tags applied to the role |

Required variables must be supplied by the calling configuration. For OIDC trust, provide a valid provider ARN, an HTTPS issuer URL, and a non-empty subject.

## Outputs

| Output | Description |
|---|---|
| `role_name` | Name of the created IAM role |
| `role_arn` | ARN of the created IAM role |
| `role_id` | Unique ID of the created IAM role |

## Security considerations

- Use the default `service` trust model unless OIDC trust is specifically required.
- For OIDC trust, restrict the `sub` condition to the exact Kubernetes service account and namespace.
- Use `sts.amazonaws.com` as the audience for standard EKS IRSA configurations.
- Grant only the managed and inline permissions required by the workload.
- Avoid wildcard subjects and unnecessarily broad IAM permissions.
- Keep the OIDC provider ARN and issuer URL aligned with the intended EKS cluster.
- Manage changes through Terraform and review the plan before applying.
- Do not commit AWS credentials, secrets, or sensitive Terraform state to Git.

For the AWS Load Balancer Controller, the service account subject is typically:

`system:serviceaccount:kube-system:aws-load-balancer-controller`

The service account name and namespace in the trust policy must match the actual Kubernetes deployment.

## Validation and tests

Run the following commands from the repository root:

```bash
terraform fmt -recursive modules/iam-role
terraform -chdir=modules/iam-role validate
terraform -chdir=modules/iam-role test
```

The module test suite covers service trust, OIDC trust restrictions, managed policy attachments, optional inline policies, and invalid input scenarios.

These commands validate and test the module without applying infrastructure changes.

## Repository structure

```text
modules/iam-role/
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── README.md
└── tests/
    └── iam-role.tftest.hcl
```
