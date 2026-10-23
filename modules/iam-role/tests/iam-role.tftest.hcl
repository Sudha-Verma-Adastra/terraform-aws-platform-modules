mock_provider "aws" {
  override_during = plan

  mock_resource "aws_iam_role" {
    defaults = {
      id        = "test-role-id"
      arn       = "arn:aws:iam::123456789012:role/test-platform-role"
      unique_id = "AROAEXAMPLEID"
    }
  }
}

run "valid_iam_role" {
  command = plan

  variables {
    role_name         = "test-platform-role"
    service_principal = "lambda.amazonaws.com"
  }

  assert {
    condition     = aws_iam_role.this.name == "test-platform-role"
    error_message = "The IAM role must use the configured role name."
  }

  assert {
    condition = (
      jsondecode(aws_iam_role.this.assume_role_policy)
      .Statement[0].Principal.Service == "lambda.amazonaws.com"
    )
    error_message = "The role trust policy must name the configured Lambda service principal."
  }

  assert {
    condition = (
      jsondecode(aws_iam_role.this.assume_role_policy)
      .Statement[0].Action == "sts:AssumeRole"
    )
    error_message = "The trust policy must allow sts:AssumeRole."
  }
}

run "attach_managed_policies" {
  command = plan

  variables {
    role_name         = "test-platform-role"
    service_principal = "lambda.amazonaws.com"
    managed_policy_arns = [
      "arn:aws:iam::aws:policy/ReadOnlyAccess",
      "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
    ]
  }

  assert {
    condition     = length(aws_iam_role_policy_attachment.managed) == 2
    error_message = "Each configured managed policy must create an attachment."
  }
}

run "omit_inline_policy_when_null" {
  command = plan

  variables {
    role_name          = "test-platform-role"
    service_principal  = "lambda.amazonaws.com"
    inline_policy_json = null
  }

  assert {
    condition     = length(aws_iam_role_policy.inline) == 0
    error_message = "No inline policy resource should be created when inline_policy_json is null."
  }
}

run "create_inline_policy_when_provided" {
  command = plan

  variables {
    role_name          = "test-platform-role"
    service_principal  = "lambda.amazonaws.com"
    inline_policy_json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"s3:ListBucket\",\"Resource\":\"arn:aws:s3:::example-bucket\"}]}"
  }

  assert {
    condition     = length(aws_iam_role_policy.inline) == 1
    error_message = "An inline policy resource must be created when a policy is provided."
  }

  assert {
    condition = (
      jsondecode(aws_iam_role_policy.inline[0].policy)
      .Statement[0].Action == "s3:ListBucket"
    )
    error_message = "The inline policy must preserve the configured permission."
  }
}

run "reject_invalid_role_name" {
  command = plan

  variables {
    role_name         = "invalid role name"
    service_principal = "lambda.amazonaws.com"
  }

  expect_failures = [var.role_name]
}

run "reject_invalid_service_principal" {
  command = plan

  variables {
    role_name         = "test-platform-role"
    service_principal = "lambda"
  }

  expect_failures = [var.service_principal]
}

run "reject_malformed_inline_policy_json" {
  command = plan

  variables {
    role_name          = "test-platform-role"
    service_principal  = "lambda.amazonaws.com"
    inline_policy_json = "{not-valid-json}"
  }

  expect_failures = [var.inline_policy_json]
}

run "oidc_trust_policy_is_restricted" {
  command = plan

  variables {
    role_name         = "test-alb-controller-role"
    service_principal = "lambda.amazonaws.com"
    trust_type        = "oidc"
    oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE123"
    oidc_issuer_url   = "https://oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE123"
    oidc_subject      = "system:serviceaccount:kube-system:aws-load-balancer-controller"
    oidc_audience     = "sts.amazonaws.com"
  }

  assert {
    condition = (
      jsondecode(aws_iam_role.this.assume_role_policy)
      .Statement[0].Action == "sts:AssumeRoleWithWebIdentity"
    )
    error_message = "OIDC trust must use sts:AssumeRoleWithWebIdentity."
  }

  assert {
    condition = (
      jsondecode(aws_iam_role.this.assume_role_policy)
      .Statement[0].Principal.Federated ==
      "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE123"
    )
    error_message = "OIDC trust must use the configured federated provider."
  }

  assert {
    condition = (
      jsondecode(aws_iam_role.this.assume_role_policy)
      .Statement[0].Condition.StringEquals[
        "oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE123:sub"
      ][0] ==
      "system:serviceaccount:kube-system:aws-load-balancer-controller"
    )
    error_message = "OIDC trust must restrict assumption to the specified service account."
  }

  assert {
    condition = (
      jsondecode(aws_iam_role.this.assume_role_policy)
      .Statement[0].Condition.StringEquals[
        "oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE123:aud"
      ][0] == "sts.amazonaws.com"
    )
    error_message = "OIDC trust must restrict the audience to sts.amazonaws.com."
  }
}

run "reject_oidc_trust_without_required_inputs" {
  command = plan

  variables {
    role_name         = "test-alb-controller-role"
    service_principal = "lambda.amazonaws.com"
    trust_type        = "oidc"
    oidc_provider_arn = null
    oidc_issuer_url   = null
    oidc_subject      = null
  }

  expect_failures = [aws_iam_role.this]
}
