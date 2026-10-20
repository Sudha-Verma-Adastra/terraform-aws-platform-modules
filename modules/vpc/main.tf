locals {
  common_tags = merge(
    {
      ManagedBy   = "Terraform"
      Project     = var.name
      Environment = "shared"
    },
    var.tags
  )

  public_subnets = {
    for index, az in var.availability_zones : tostring(index) => {
      availability_zone = az
      cidr_block        = var.public_subnet_cidrs[index]
    }
  }

  private_subnets = {
    for index, az in var.availability_zones : tostring(index) => {
      availability_zone = az
      cidr_block        = var.private_subnet_cidrs[index]
    }
  }
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "${var.name}-vpc"
  })

  lifecycle {
    precondition {
      condition = (
        length(var.public_subnet_cidrs) == length(var.availability_zones) &&
        length(var.private_subnet_cidrs) == length(var.availability_zones)
      )
      error_message = "Public and private subnet CIDR lists must each have one entry per Availability Zone."
    }

    precondition {
      condition = length(distinct(concat(
        var.public_subnet_cidrs,
        var.private_subnet_cidrs
        ))) == (
        length(var.public_subnet_cidrs) +
        length(var.private_subnet_cidrs)
      )
      error_message = "Subnet CIDR blocks must not be duplicated."
    }
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.name}-igw"
  })
}

resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.name}-public-${each.value.availability_zone}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    Name = "${var.name}-private-${each.value.availability_zone}"
    Tier = "private"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.name}-public-rt"
    Tier = "public"
  })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  for_each = local.private_subnets

  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.name}-private-rt-${each.value.availability_zone}"
    Tier = "private"
  })
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}
