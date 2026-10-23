variable "role_name" {
  description = "Name of the IAM role."
  type        = string

  validation {
    condition = (
      length(var.role_name) >= 1 &&
      length(var.role_name) <= 64 &&
      can(regex("^[A-Za-z0-9_+=,.@-]+$", var.role_name))
    )
    error_message = "role_name must be 1-64 characters and contain only valid IAM role name characters."
  }
}

variable "service_principal" {
  description = "AWS service principal for service-based trust."
  type        = string
  default     = "lambda.amazonaws.com"

  validation {
    condition = (
      var.trust_type != "service" ||
      can(regex(
        "^[a-z0-9.-]+\\.amazonaws\\.com(\\.cn)?$",
        var.service_principal
      ))
    )
    error_message = "For service trust, service_principal must be a valid AWS service principal."
  }
}

variable "managed_policy_arns" {
  description = "Optional list of AWS-managed or customer-managed policy ARNs to attach."
  type        = list(string)
  default     = []
}

variable "inline_policy_json" {
  description = "Optional JSON IAM permissions policy. Leave null if not required."
  type        = string
  default     = null

  validation {
    condition     = var.inline_policy_json == null ? true : can(jsondecode(var.inline_policy_json))
    error_message = "inline_policy_json must contain valid JSON when provided."
  }
}

variable "tags" {
  description = "Additional tags for the role."
  type        = map(string)
  default     = {}
}

variable "trust_type" {
  description = "Trust model for the role: service or oidc."
  type        = string
  default     = "service"

  validation {
    condition     = contains(["service", "oidc"], var.trust_type)
    error_message = "trust_type must be service or oidc."
  }
}

variable "oidc_provider_arn" {
  description = "IAM OIDC provider ARN used for federated trust."
  type        = string
  default     = null
  nullable    = true
}

variable "oidc_issuer_url" {
  description = "EKS OIDC issuer URL, including https://."
  type        = string
  default     = null
  nullable    = true
}

variable "oidc_subject" {
  description = "Exact OIDC subject allowed to assume this role."
  type        = string
  default     = null
  nullable    = true
}

variable "oidc_audience" {
  description = "Expected OIDC audience."
  type        = string
  default     = "sts.amazonaws.com"
}
