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
  description = "AWS service allowed to assume the role, such as lambda.amazonaws.com."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9.-]+\\.amazonaws\\.com$", var.service_principal))
    error_message = "Provide a valid AWS service principal, such as lambda.amazonaws.com."
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