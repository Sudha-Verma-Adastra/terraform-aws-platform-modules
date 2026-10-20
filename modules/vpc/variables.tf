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
