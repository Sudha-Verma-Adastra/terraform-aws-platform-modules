variable "name" {
  description = "Name of the compute instance."
  type        = string

  validation {
    condition     = length(trimspace(var.name)) > 0
    error_message = "The name must not be empty."
  }
}

variable "ami_id" {
  description = "AMI ID used to launch the EC2 instance."
  type        = string

  validation {
    condition     = can(regex("^ami-[0-9a-f]+$", var.ami_id))
    error_message = "Provide a valid AMI ID."
  }
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.small"
}

variable "vpc_id" {
  description = "VPC ID for the instance security group."
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the instance will be launched."
  type        = string
}

variable "iam_instance_profile_name" {
  description = "Optional existing IAM instance profile."
  type        = string
  default     = null
  nullable    = true
}

variable "associate_public_ip_address" {
  description = "Whether to associate a public IPv4 address."
  type        = bool
  default     = false
}

variable "root_volume_size" {
  description = "Encrypted root EBS volume size in GiB."
  type        = number
  default     = 20

  validation {
    condition     = var.root_volume_size >= 8 && var.root_volume_size <= 16384
    error_message = "Volume size must be between 8 and 16384 GiB."
  }
}

variable "ingress_rules" {
  description = "IPv4 ingress rules for the instance security group."
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_ipv4   = string
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.ingress_rules :
      rule.from_port >= 0 &&
      rule.to_port >= rule.from_port &&
      contains(["tcp", "udp", "icmp", "-1"], rule.protocol) &&
      can(cidrhost(rule.cidr_ipv4, 0))
    ])
    error_message = "Ingress rules must use valid ports, supported protocols, and IPv4 CIDRs."
  }
}

variable "tags" {
  description = "Tags applied to the instance and security group."
  type        = map(string)
  default     = {}
}