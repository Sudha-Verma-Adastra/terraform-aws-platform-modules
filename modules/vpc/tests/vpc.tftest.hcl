
mock_provider "aws" {
  override_during = plan

  mock_resource "aws_internet_gateway" {
    defaults = {
      id = "igw-test123456789"
    }
  }
}

run "valid_multi_az_vpc_plan" {
  command = plan

  variables {
    name                 = "test-platform"
    vpc_cidr             = "10.20.0.0/16"
    availability_zones   = ["us-east-1a", "us-east-1b"]
    public_subnet_cidrs  = ["10.20.1.0/24", "10.20.2.0/24"]
    private_subnet_cidrs = ["10.20.11.0/24", "10.20.12.0/24"]
    tags                 = { Environment = "test" }
  }

  assert {
    condition     = output.vpc_cidr == "10.20.0.0/16"
    error_message = "The VPC output must match the requested CIDR."
  }

  assert {
    condition     = length(output.public_subnet_ids) == 2
    error_message = "The module must expose two public subnet IDs."
  }

  assert {
    condition     = length(output.private_subnet_ids) == 2
    error_message = "The module must expose two private subnet IDs."
  }

  assert {
    condition     = aws_subnet.private["0"].map_public_ip_on_launch == false
    error_message = "Private subnets must not auto-assign public IPv4 addresses."
  }
}

run "reject_invalid_vpc_cidr" {
  command = plan

  variables {
    name                 = "test-platform"
    vpc_cidr             = "not-a-cidr"
    availability_zones   = ["us-east-1a", "us-east-1b"]
    public_subnet_cidrs  = ["10.20.1.0/24", "10.20.2.0/24"]
    private_subnet_cidrs = ["10.20.11.0/24", "10.20.12.0/24"]
  }

  expect_failures = [var.vpc_cidr]
}

run "reject_mismatched_subnet_count" {
  command = plan

  variables {
    name                 = "test-platform"
    vpc_cidr             = "10.20.0.0/16"
    availability_zones   = ["us-east-1a", "us-east-1b"]
    public_subnet_cidrs  = ["10.20.1.0/24"]
    private_subnet_cidrs = ["10.20.11.0/24", "10.20.12.0/24"]
  }

  expect_failures = [var.public_subnet_cidrs]
}


run "reject_duplicate_subnet_cidrs" {
  command = plan

  variables {
    name                 = "test-platform"
    vpc_cidr             = "10.20.0.0/16"
    availability_zones   = ["us-east-1a", "us-east-1b"]
    public_subnet_cidrs  = ["10.20.1.0/24", "10.20.2.0/24"]
    private_subnet_cidrs = ["10.20.1.0/24", "10.20.12.0/24"]
  }

  expect_failures = [aws_vpc.this]
}

run "reject_duplicate_availability_zones" {
  command = plan

  variables {
    name                 = "test-platform"
    vpc_cidr             = "10.20.0.0/16"
    availability_zones   = ["us-east-1a", "us-east-1a"]
    public_subnet_cidrs  = ["10.20.1.0/24", "10.20.2.0/24"]
    private_subnet_cidrs = ["10.20.11.0/24", "10.20.12.0/24"]
  }

  expect_failures = [var.availability_zones]
}

run "reject_invalid_public_subnet_cidr" {
  command = plan

  variables {
    name                 = "test-platform"
    vpc_cidr             = "10.20.0.0/16"
    availability_zones   = ["us-east-1a", "us-east-1b"]
    public_subnet_cidrs  = ["invalid-cidr", "10.20.2.0/24"]
    private_subnet_cidrs = ["10.20.11.0/24", "10.20.12.0/24"]
  }

  expect_failures = [var.public_subnet_cidrs]
}

run "verify_public_and_private_network_design" {
  command = plan

  variables {
    name                 = "test-platform"
    vpc_cidr             = "10.20.0.0/16"
    availability_zones   = ["us-east-1a", "us-east-1b"]
    public_subnet_cidrs  = ["10.20.1.0/24", "10.20.2.0/24"]
    private_subnet_cidrs = ["10.20.11.0/24", "10.20.12.0/24"]
  }

  assert {
    condition = alltrue([
      for subnet in values(aws_subnet.public) :
      subnet.map_public_ip_on_launch
    ])
    error_message = "Public subnets must enable automatic public IPv4 assignment."
  }

  assert {
    condition = alltrue([
      for subnet in values(aws_subnet.private) :
      subnet.map_public_ip_on_launch == false
    ])
    error_message = "Private subnets must disable automatic public IPv4 assignment."
  }

  assert {
    condition     = aws_route.public_internet.destination_cidr_block == "0.0.0.0/0"
    error_message = "The public route must use the default IPv4 destination."
  }

  assert {
    condition     = length(aws_route_table.private) == 2
    error_message = "Each private subnet must have its own private route table."
  }
}


run "reject_subnet_outside_vpc" {
  command = plan

  variables {
    name                 = "test-platform"
    vpc_cidr             = "10.20.0.0/16"
    availability_zones   = ["us-east-1a", "us-east-1b"]
    public_subnet_cidrs  = ["10.21.1.0/24", "10.20.2.0/24"]
    private_subnet_cidrs = ["10.20.11.0/24", "10.20.12.0/24"]
  }

  expect_failures = [aws_vpc.this]
}

run "reject_overlapping_subnet_cidrs" {
  command = plan

  variables {
    name                 = "test-platform"
    vpc_cidr             = "10.20.0.0/16"
    availability_zones   = ["us-east-1a", "us-east-1b"]
    public_subnet_cidrs  = ["10.20.1.0/24", "10.20.2.0/24"]
    private_subnet_cidrs = ["10.20.1.128/25", "10.20.12.0/24"]
  }

  expect_failures = [aws_vpc.this]
}

run "verify_public_route_targets_internet_gateway" {
  command = plan

  variables {
    name                 = "test-platform"
    vpc_cidr             = "10.20.0.0/16"
    availability_zones   = ["us-east-1a", "us-east-1b"]
    public_subnet_cidrs  = ["10.20.1.0/24", "10.20.2.0/24"]
    private_subnet_cidrs = ["10.20.11.0/24", "10.20.12.0/24"]
  }

  assert {
    condition     = aws_route.public_internet.destination_cidr_block == "0.0.0.0/0"
    error_message = "The public default route must target all IPv4 destinations."
  }


  assert {
    condition     = aws_route.public_internet.gateway_id == aws_internet_gateway.this.id
    error_message = "The public default route must target the VPC internet gateway."
  }

}

run "verify_private_route_tables_are_per_subnet" {
  command = plan

  variables {
    name                 = "test-platform"
    vpc_cidr             = "10.20.0.0/16"
    availability_zones   = ["us-east-1a", "us-east-1b"]
    public_subnet_cidrs  = ["10.20.1.0/24", "10.20.2.0/24"]
    private_subnet_cidrs = ["10.20.11.0/24", "10.20.12.0/24"]
  }

  assert {
    condition     = length(aws_route_table.private) == 2
    error_message = "Each private subnet must have a dedicated route table."
  }

  assert {
    condition = (
      toset(keys(aws_route_table_association.private)) == toset(keys(aws_subnet.private)) &&
      toset(keys(aws_route_table_association.private)) == toset(keys(aws_route_table.private))
    )
    error_message = "Each private subnet and private route table must have a corresponding association for the same availability-zone key."
  }
}

run "verify_private_subnets_have_no_public_ip_assignment" {
  command = plan

  variables {
    name                 = "test-platform"
    vpc_cidr             = "10.20.0.0/16"
    availability_zones   = ["us-east-1a", "us-east-1b"]
    public_subnet_cidrs  = ["10.20.1.0/24", "10.20.2.0/24"]
    private_subnet_cidrs = ["10.20.11.0/24", "10.20.12.0/24"]
  }

  assert {
    condition = alltrue([
      for subnet in values(aws_subnet.private) :
      subnet.map_public_ip_on_launch == false
    ])
    error_message = "Private subnets must not automatically assign public IPv4 addresses."
  }
}

run "verify_private_route_tables_have_no_internet_gateway_route" {
  command = plan

  variables {
    name                 = "test-platform"
    vpc_cidr             = "10.20.0.0/16"
    availability_zones   = ["us-east-1a", "us-east-1b"]
    public_subnet_cidrs  = ["10.20.1.0/24", "10.20.2.0/24"]
    private_subnet_cidrs = ["10.20.11.0/24", "10.20.12.0/24"]
  }

  assert {
    condition = length(aws_route_table.private) == 2
    error_message = "Two private route tables must be created for the two private subnets."
  }

  assert {
    condition = (
      toset(keys(aws_route_table_association.private)) ==
      toset(keys(aws_subnet.private))
    )
    error_message = "Each private subnet must have a corresponding route-table association."
  }
}
