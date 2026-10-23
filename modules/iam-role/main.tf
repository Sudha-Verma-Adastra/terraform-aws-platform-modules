locals {
  service_assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = var.service_principal
        }
      }
    ]
  })

  oidc_issuer_key = var.oidc_issuer_url == null ? "" : trimprefix(var.oidc_issuer_url, "https://")

  oidc_assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRoleWithWebIdentity"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${local.oidc_issuer_key}:sub" = [var.oidc_subject]
            "${local.oidc_issuer_key}:aud" = [var.oidc_audience]
          }
        }
      }
    ]
  })
}

resource "aws_iam_role" "this" {
  name = var.role_name

  assume_role_policy = (
    var.trust_type == "oidc"
    ? local.oidc_assume_role_policy
    : local.service_assume_role_policy
  )

  tags = merge(
    {
      ManagedBy = "Terraform"
    },
    var.tags
  )

  lifecycle {
    precondition {
      condition = (
        var.trust_type != "oidc" ||
        (
          var.oidc_provider_arn != null &&
          var.oidc_issuer_url != null &&
          var.oidc_subject != null &&
          trimspace(var.oidc_provider_arn) != "" &&
          trimspace(var.oidc_issuer_url) != "" &&
          trimspace(var.oidc_subject) != "" &&
          startswith(var.oidc_issuer_url, "https://")
        )
      )
      error_message = "For OIDC trust, provide a provider ARN, HTTPS issuer URL, and non-empty subject."
    }
  }
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = toset(var.managed_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "inline" {
  count = var.inline_policy_json == null ? 0 : 1

  name   = "${var.role_name}-inline-policy"
  role   = aws_iam_role.this.id
  policy = var.inline_policy_json
}