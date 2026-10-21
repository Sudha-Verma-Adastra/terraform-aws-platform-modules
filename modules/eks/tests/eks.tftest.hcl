mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Principal\":{\"Service\":\"eks.amazonaws.com\"}}]}"
    }
  }
}

run "valid_configuration" {
  command = plan

  variables {
    cluster_name       = "platform-test"
    cluster_version    = "1.31"
    cluster_subnet_ids = ["subnet-11111111", "subnet-22222222"]
    node_subnet_ids    = ["subnet-33333333", "subnet-44444444"]

    endpoint_private_access = true
    endpoint_public_access  = false

    node_group_name = "workers"
    instance_types  = ["t3.medium"]
    capacity_type   = "ON_DEMAND"

    min_size     = 1
    desired_size = 2
    max_size     = 3
    disk_size    = 20

    tags = {
      Environment = "test"
      Project     = "platform"
    }
  }

  assert {
    condition     = aws_eks_cluster.this.name == "platform-test"
    error_message = "The EKS cluster name should match the configured value."
  }

  assert {
    condition     = aws_eks_cluster.this.vpc_config[0].endpoint_private_access
    error_message = "Private Kubernetes API endpoint access should be enabled."
  }

  assert {
    condition     = !aws_eks_cluster.this.vpc_config[0].endpoint_public_access
    error_message = "Public Kubernetes API endpoint access should be disabled."
  }

  assert {
    condition     = length(aws_eks_cluster.this.enabled_cluster_log_types) == 5
    error_message = "All five configured EKS control-plane log types should be enabled."
  }

  assert {
    condition     = aws_eks_node_group.this.scaling_config[0].desired_size == 2
    error_message = "The node group's desired capacity should be two."
  }

  assert {
    condition     = aws_eks_node_group.this.scaling_config[0].min_size == 1
    error_message = "The node group's minimum capacity should be one."
  }

  assert {
    condition     = aws_eks_node_group.this.scaling_config[0].max_size == 3
    error_message = "The node group's maximum capacity should be three."
  }
}

run "rejects_invalid_cluster_name" {
  command = plan

  variables {
    cluster_name       = "invalid cluster name!"
    cluster_version    = "1.31"
    cluster_subnet_ids = ["subnet-11111111", "subnet-22222222"]
    node_subnet_ids    = ["subnet-33333333", "subnet-44444444"]
  }

  expect_failures = [var.cluster_name]
}

run "rejects_invalid_scaling_range" {
  command = plan

  variables {
    cluster_name       = "platform-test"
    cluster_version    = "1.31"
    cluster_subnet_ids = ["subnet-11111111", "subnet-22222222"]
    node_subnet_ids    = ["subnet-33333333", "subnet-44444444"]

    min_size     = 3
    desired_size = 2
    max_size     = 1
  }

  expect_failures = [
    var.max_size
  ]
}

run "requires_cidrs_for_public_endpoint" {
  command = plan

  variables {
    cluster_name       = "platform-test"
    cluster_version    = "1.31"
    cluster_subnet_ids = ["subnet-11111111", "subnet-22222222"]
    node_subnet_ids    = ["subnet-33333333", "subnet-44444444"]

    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = []
  }

  expect_failures = [var.public_access_cidrs]
}
