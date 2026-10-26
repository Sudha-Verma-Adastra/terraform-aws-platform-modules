variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string

  validation {
    condition = (
      length(var.cluster_name) >= 1 &&
      length(var.cluster_name) <= 40 &&
      can(regex("^[A-Za-z0-9][A-Za-z0-9_-]*$", var.cluster_name))
    )
    error_message = "cluster_name must be 1-40 characters, start with a letter or number, and contain only letters, numbers, hyphens, or underscores."
  }
}

variable "cluster_version" {
  description = "Kubernetes version supported by Amazon EKS in the target region."
  type        = string

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+$", var.cluster_version))
    error_message = "cluster_version must use major.minor format, for example 1.XX."
  }
}

variable "cluster_subnet_ids" {
  description = "At least two subnet IDs for the EKS control plane network configuration."
  type        = list(string)

  validation {
    condition = (
      length(var.cluster_subnet_ids) >= 2 &&
      length(distinct(var.cluster_subnet_ids)) == length(var.cluster_subnet_ids)
    )
    error_message = "Provide at least two unique cluster subnet IDs."
  }
}

variable "node_subnet_ids" {
  description = "At least two subnet IDs for managed worker nodes, preferably private subnets."
  type        = list(string)

  validation {
    condition = (
      length(var.node_subnet_ids) >= 2 &&
      length(distinct(var.node_subnet_ids)) == length(var.node_subnet_ids)
    )
    error_message = "Provide at least two unique node subnet IDs."
  }
}

variable "endpoint_private_access" {
  description = "Enable private access to the Kubernetes API endpoint."
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public access to the Kubernetes API endpoint."
  type        = bool
  default     = false
}

variable "public_access_cidrs" {
  description = "Allowed IPv4 CIDRs for public Kubernetes API endpoint access."
  type        = list(string)
  default     = []

  validation {
    condition = (
      length(var.public_access_cidrs) > 0 ||
      !var.endpoint_public_access
    )
    error_message = "Specify public_access_cidrs when public endpoint access is enabled."
  }

  validation {
    condition = alltrue([
      for cidr in var.public_access_cidrs : can(cidrnetmask(cidr))
    ])
    error_message = "Every public_access_cidrs entry must be a valid IPv4 CIDR."
  }
}

variable "node_group_name" {
  description = "Name of the managed node group."
  type        = string
  default     = "default"

  validation {
    condition = (
      length(var.node_group_name) >= 1 &&
      length(var.node_group_name) <= 63 &&
      can(regex("^[A-Za-z0-9][A-Za-z0-9_-]*$", var.node_group_name))
    )
    error_message = "node_group_name must be 1-63 characters and contain only letters, numbers, hyphens, or underscores."
  }
}

variable "instance_types" {
  description = "EC2 instance types for the managed node group."
  type        = list(string)
  default     = ["t3.medium"]

  validation {
    condition     = length(var.instance_types) > 0
    error_message = "Provide at least one EC2 instance type."
  }
}

variable "capacity_type" {
  description = "Managed node group capacity type: ON_DEMAND or SPOT."
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.capacity_type)
    error_message = "capacity_type must be ON_DEMAND or SPOT."
  }
}

variable "desired_size" {
  description = "Desired number of worker nodes."
  type        = number
  default     = 2

  validation {
    condition     = var.desired_size >= 1 && var.desired_size == floor(var.desired_size)
    error_message = "desired_size must be a positive integer."
  }
}

variable "min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 1

  validation {
    condition     = var.min_size >= 1 && var.min_size == floor(var.min_size)
    error_message = "min_size must be a positive integer."
  }
}

variable "max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 3

  validation {
    condition = (
      var.max_size >= 1 &&
      var.max_size == floor(var.max_size)
    )
    error_message = "max_size must be a positive integer."
  }

  validation {
    condition     = var.min_size <= var.max_size
    error_message = "min_size must be less than or equal to max_size."
  }

  validation {
    condition     = var.desired_size <= var.max_size
    error_message = "desired_size must be less than or equal to max_size."
  }
}

variable "disk_size" {
  description = "Worker node root volume size in GiB."
  type        = number
  default     = 20

  validation {
    condition     = var.disk_size >= 20 && var.disk_size == floor(var.disk_size)
    error_message = "disk_size must be an integer of at least 20 GiB."
  }
}

variable "tags" {
  description = "Additional tags applied to supported EKS resources."
  type        = map(string)
  default     = {}
}

variable "create_iam_roles" {
  description = "Whether this module should create EKS cluster and node IAM roles."
  type        = bool
  default     = true
}

variable "existing_cluster_role_name" {
  description = "Name of the existing EKS cluster IAM role when create_iam_roles is false."
  type        = string
  default     = "eksClusterRole"
}

variable "existing_node_role_name" {
  description = "Name of the existing EKS node IAM role when create_iam_roles is false."
  type        = string
  default     = "AmazonEKSNodeRole"
}
