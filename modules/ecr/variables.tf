variable "repository_name" {
  description = "Name of the private ECR repository."
  type        = string

  validation {
    condition = (
      length(var.repository_name) >= 2 &&
      length(var.repository_name) <= 256 &&
      can(regex("^[a-z0-9]+([._/-][a-z0-9]+)*$", var.repository_name))
    )
    error_message = "Repository name must be 2-256 characters, use lowercase letters, numbers, hyphens, underscores or slashes, and must not start or end with a separator."
  }
}

variable "image_tag_mutability" {
  description = "Whether image tags can be overwritten."
  type        = string
  default     = "IMMUTABLE"

  validation {
    condition = contains(
      ["MUTABLE", "IMMUTABLE"],
      var.image_tag_mutability
    )
    error_message = "image_tag_mutability must be MUTABLE or IMMUTABLE."
  }
}

variable "scan_on_push" {
  description = "Enable image vulnerability scanning on push."
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "Encryption type for the repository."
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_type)
    error_message = "encryption_type must be AES256 or KMS."
  }
}

variable "kms_key" {
  description = "Optional KMS key ARN. Required when encryption_type is KMS."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = (
      var.encryption_type == "KMS" ?
      (var.kms_key != null && trimspace(var.kms_key) != "") :
      var.kms_key == null
    )
    error_message = "Provide kms_key when encryption_type is KMS, and omit it when using AES256."
  }
}

variable "create_lifecycle_policy" {
  description = "Whether to create an image lifecycle policy."
  type        = bool
  default     = true
}

variable "max_image_count" {
  description = "Maximum number of images retained by the lifecycle policy."
  type        = number
  default     = 20

  validation {
    condition     = var.max_image_count >= 1 && var.max_image_count == floor(var.max_image_count)
    error_message = "max_image_count must be a positive integer."
  }
}

variable "tags" {
  description = "Additional resource tags."
  type        = map(string)
  default     = {}
}
