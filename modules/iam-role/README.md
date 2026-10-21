# AWS IAM Role Module

A reusable Terraform module for creating AWS IAM roles with a service trust policy and optional managed or inline permissions policies.

## Features

- Service-based IAM trust policy using `sts:AssumeRole`.
- Role-name validation.
- Service-principal format validation.
- Optional AWS-managed or customer-managed policy attachments.
- Optional inline permissions policy.
- JSON syntax validation for inline policy input.
- Resource tagging, including `ManagedBy = Terraform`.
- Reusable role name, ARN, and unique ID outputs.

## Security Considerations

- Follow least privilege when selecting managed policies and defining inline permissions.
- Prefer narrow resource ARNs and only the actions required by the workload.
- Valid JSON does not guarantee a semantically valid or least-privilege IAM policy.
- The service-principal validation checks the expected hostname format; it does not prove that the service exists or that it should be trusted.
- Review trust relationships and permissions before deploying.
- This module does not currently configure OIDC federation, cross-account trust, permissions boundaries, or IAM policy conditions.

## Inputs

| Name | Type | Required | Description |
|---|---|---|---|
| `role_name` | `string` | Yes | IAM role name |
| `service_principal` | `string` | Yes | AWS service principal, such as `lambda.amazonaws.com` |
| `managed_policy_arns` | `list(string)` | No | Managed policy ARNs to attach; defaults to `[]` |
| `inline_policy_json` | `string` | No | Optional inline permissions policy JSON; defaults to `null` |
| `tags` | `map(string)` | No | Additional role tags; defaults to `{}` |

## Outputs

| Name | Description |
|---|---|
| `role_name` | IAM role name |
| `role_arn` | IAM role ARN |
| `role_id` | IAM role unique ID |

## Testing

Run from the repository root:

```bash
terraform -chdir=modules/iam-role fmt -check
terraform -chdir=modules/iam-role init -backend=false
terraform -chdir=modules/iam-role validate
terraform -chdir=modules/iam-role test
```

The current native test suite contains seven test runs covering:

1. Role name and service trust policy.
2. `sts:AssumeRole` trust action.
3. Managed policy attachments.
4. Omission of the inline policy when input is `null`.
5. Creation and configured action of an inline policy.
6. Rejection of invalid role names.
7. Rejection of invalid service principals and malformed inline policy JSON.

The tests use Terraform's native test framework and a mocked AWS provider. They validate selected configuration behavior without deploying IAM resources to AWS.

## Troubleshooting

See [`../../docs/iam-role-troubleshooting.md`](../../docs/iam-role-troubleshooting.md) for test errors, root causes, fixes, and validation notes.
