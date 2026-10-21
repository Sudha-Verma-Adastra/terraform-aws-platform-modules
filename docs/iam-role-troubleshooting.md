# IAM Role Module Troubleshooting Log

This document records issues encountered while developing native Terraform tests for `modules/iam-role`.

The tests use a mocked AWS provider and plan-based runs. Passing tests do not establish that the IAM role has been deployed or that its permissions are appropriate for a live workload.

## Summary

| Issue | Root cause | Resolution |
|---|---|---|
| Trust-policy assertion failed with `Invalid function argument` | The mocked trust policy represented `Action` as a string, but the assertion attempted to convert it to a list | Compare the string directly with `sts:AssumeRole` |
| Later tests skipped after the first assertion failed | Test execution stopped at the failing run | Corrected the assertion and reran the suite |

## 1. Trust-policy assertion: string incorrectly converted to a list

### Symptom

The `valid_iam_role` test failed on an assertion using:

```hcl
contains(
  tolist(jsondecode(aws_iam_role.this.assume_role_policy).Statement[0].Action),
  "sts:AssumeRole"
)
```

Terraform reported that it could not convert a string to a list.

### Root cause

The trust-policy statement represented `Action` as the string `"sts:AssumeRole"`. The assertion incorrectly assumed that it was a collection.

### Fix

The assertion was changed to compare the action directly:

```hcl
assert {
  condition = (
    jsondecode(aws_iam_role.this.assume_role_policy)
      .Statement[0].Action == "sts:AssumeRole"
  )
  error_message = "The trust policy must allow sts:AssumeRole."
}
```

### Validation

The user subsequently reported that the IAM test suite succeeded.

## 2. Later tests skipped after the initial failure

### Symptom

The first run reported one failed test and six skipped tests.

### Root cause

The first test failure prevented the remaining runs in that test file from completing.

### Resolution

After correcting the assertion, the user reran the suite and reported success.

## 3. Repeatable validation

Run from the repository root:

```bash
terraform -chdir=modules/iam-role fmt -check
terraform -chdir=modules/iam-role init -backend=false
terraform -chdir=modules/iam-role validate
terraform -chdir=modules/iam-role test
```

When troubleshooting future failures:

1. Capture the exact failing test and error.
2. Determine whether the issue is in the module, provider schema, or assertion.
3. Make the smallest targeted change.
4. Rerun formatting, validation, and the complete test suite.
5. Record the observed result; do not assume success before the run completes.

## Official references

- Terraform test framework: https://developer.hashicorp.com/terraform/language/tests
- Terraform provider mocking: https://developer.hashicorp.com/terraform/language/tests/mocking
- AWS IAM roles: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html
- IAM policy grammar: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_grammar.html
