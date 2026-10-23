variable "name" {
  description = "Name prefix used to identify resources."
  type        = string

  validation {
    condition     = length(trimspace(var.name)) > 0
    error_message = "The name must not be empty."
  }
}

variable "vpc_cidr" {
  description = "IPv4 CIDR range for the VPC."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "At least two Availability Zones for subnet distribution."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "Provide at least two Availability Zones."
  }

  validation {
    condition     = length(distinct(var.availability_zones)) == length(var.availability_zones)
    error_message = "Availability Zones must be unique."
  }
}

variable "public_subnet_cidrs" {
  description = "One public subnet CIDR per Availability Zone, in matching order."
  type        = list(string)

  validation {
    condition     = alltrue([for cidr in var.public_subnet_cidrs : can(cidrnetmask(cidr))])
    error_message = "Every public subnet CIDR must be a valid IPv4 CIDR block."
  }

  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "At least two public subnet CIDRs are required."
  }
}

variable "private_subnet_cidrs" {
  description = "One private subnet CIDR per Availability Zone, in matching order."
  type        = list(string)

  validation {
    condition     = alltrue([for cidr in var.private_subnet_cidrs : can(cidrnetmask(cidr))])
    error_message = "Every private subnet CIDR must be a valid IPv4 CIDR block."
  }

  validation {
    condition     = length(var.private_subnet_cidrs) >= 2
    error_message = "At least two private subnet CIDRs are required."
  }
}

variable "tags" {
  description = "Additional tags applied to supported resources."
  type        = map(string)
  default     = {}
}


variable "enable_nat_gateway" {
  description = "Whether to create NAT Gateway resources."
  type        = bool
  default     = false
}

variable "nat_gateway_mode" {
  description = "NAT deployment mode: single or per_az."
  type        = string
  default     = "single"

  validation {
    condition     = contains(["single", "per_az"], var.nat_gateway_mode)
    error_message = "nat_gateway_mode must be single or per_az."
  }
}

variable "enable_s3_endpoint" {
  description = "Whether to create the S3 Gateway VPC endpoint."
  type        = bool
  default     = false
}

variable "enable_ecr_endpoints" {
  description = "Whether to create ECR API and Docker interface endpoints."
  type        = bool
  default     = false
}

variable "enable_cloudwatch_logs_endpoint" {
  description = "Whether to create the CloudWatch Logs interface endpoint."
  type        = bool
  default     = false
}

variable "enable_sts_endpoint" {
  description = "Whether to create the STS interface endpoint."
  type        = bool
  default     = false
}

variable "endpoint_allowed_cidrs" {
  description = "CIDR blocks allowed to connect to interface endpoints over HTTPS. Defaults to private subnet CIDRs when empty."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.endpoint_allowed_cidrs :
      can(cidrnetmask(cidr))
    ])
    error_message = "Every endpoint_allowed_cidrs entry must be a valid IPv4 CIDR."
  }
}
