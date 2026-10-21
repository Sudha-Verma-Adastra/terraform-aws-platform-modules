# S3 Bucket Module Troubleshooting Log

This document records issues encountered while developing the native Terraform tests for `modules/s3-bucket`.

The tests use a mocked AWS provider and plan-based runs. Passing tests do not mean the module has been deployed or verified in a live AWS account.

## Summary

| Issue | Root cause | Resolution |
|---|---|---|
| Encryption test failed with `Cannot index a set value` | Terraform represents the `rule` block as a set, which cannot be accessed with `[0]` | Iterate over the set using a `for` expression |
| Remaining tests skipped after encryption failure | Terraform stopped the test file after the failing run | Fixed the first failure and reran the suite |

## 1. Encryption assertion: Cannot index a set value

### Symptom

The `enable_default_encryption` test failed on this expression:

```hcl
aws_s3_bucket_server_side_encryption_configuration.this.rule[0]
```

Terraform reported:

```text
Error: Cannot index a set value

Block type "rule" is represented by a set of objects, and set elements do not have addressable keys.
```

### Root cause

The AWS provider schema represents the `rule` nested block as a set. Sets do not support positional indexing such as `[0]`.

This was a test-expression issue, not evidence that the S3 encryption resource itself was incorrectly configured.

### Fix

The assertion was changed to iterate over the rule set:

```hcl
assert {
  condition = alltrue([
    for rule in aws_s3_bucket_server_side_encryption_configuration.this.rule :
    rule.apply_server_side_encryption_by_default[0].sse_algorithm == "AES256"
  ])
  error_message = "S3 default server-side encryption must use AES256."
}
```

This evaluates the configured encryption algorithm without attempting to index the set.

### Validation

After applying the assertion change, the user reported that the S3 test suite succeeded.

The full test output should be rerun and retained when validating later changes.

## 2. Tests skipped after a failed run

### Symptom

The first test run reported two passing tests, one failure, and five skipped tests.

### Root cause

The test execution stopped at the failed encryption assertion, so later runs in the file were skipped.

### Resolution

The set-indexing assertion was corrected, and the test suite was rerun.

## 3. Repeatable validation commands

Run these commands from the repository root:

```bash
terraform -chdir=modules/s3-bucket fmt -check
terraform -chdir=modules/s3-bucket init -backend=false
terraform -chdir=modules/s3-bucket validate
terraform -chdir=modules/s3-bucket test
```

If a future run fails:

1. Capture the exact error and failing test name.
2. Identify whether the failure is in Terraform configuration, provider schema, or the test assertion.
3. Make the smallest targeted change.
4. Rerun formatting, validation, and the complete test suite.
5. Record the exact result rather than assuming the fix succeeded.

## Official references

- Terraform test framework: https://developer.hashicorp.com/terraform/language/tests
- Terraform provider mocking: https://developer.hashicorp.com/terraform/language/tests/mocking
- AWS S3 Block Public Access: https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-control-block-public-access.html
- AWS S3 default encryption: https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingEncryption.html
- AWS S3 versioning: https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html
