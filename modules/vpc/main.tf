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

  all_subnet_cidrs = concat(
    var.public_subnet_cidrs,
    var.private_subnet_cidrs
  )

  vpc_start_ip = try(cidrhost(var.vpc_cidr, 0), "0.0.0.0")
  vpc_end_ip   = try(cidrhost(var.vpc_cidr, -1), "0.0.0.0")

  vpc_start_num = (
    tonumber(split(".", local.vpc_start_ip)[0]) * 16777216 +
    tonumber(split(".", local.vpc_start_ip)[1]) * 65536 +
    tonumber(split(".", local.vpc_start_ip)[2]) * 256 +
    tonumber(split(".", local.vpc_start_ip)[3])
  )

  vpc_end_num = (
    tonumber(split(".", local.vpc_end_ip)[0]) * 16777216 +
    tonumber(split(".", local.vpc_end_ip)[1]) * 65536 +
    tonumber(split(".", local.vpc_end_ip)[2]) * 256 +
    tonumber(split(".", local.vpc_end_ip)[3])
  )

  subnet_ranges = [
    for cidr in local.all_subnet_cidrs : {
      cidr     = cidr
      start_ip = try(cidrhost(cidr, 0), "0.0.0.0")
      end_ip   = try(cidrhost(cidr, -1), "0.0.0.0")

      start_num = try(
        tonumber(split(".", cidrhost(cidr, 0))[0]) * 16777216 +
        tonumber(split(".", cidrhost(cidr, 0))[1]) * 65536 +
        tonumber(split(".", cidrhost(cidr, 0))[2]) * 256 +
        tonumber(split(".", cidrhost(cidr, 0))[3]),
        -1
      )

      end_num = try(
        tonumber(split(".", cidrhost(cidr, -1))[0]) * 16777216 +
        tonumber(split(".", cidrhost(cidr, -1))[1]) * 65536 +
        tonumber(split(".", cidrhost(cidr, -1))[2]) * 256 +
        tonumber(split(".", cidrhost(cidr, -1))[3]),
        -1
      )
    }
  ]
  subnet_cidrs_are_non_overlapping = alltrue(flatten([
    for i, subnet_a in local.subnet_ranges : [
      for j, subnet_b in local.subnet_ranges :
      i == j ? true : (
        subnet_a.end_num < subnet_b.start_num ||
        subnet_b.end_num < subnet_a.start_num
      )
    ]
  ]))

  subnet_cidrs_are_within_vpc = (
    !can(cidrnetmask(var.vpc_cidr)) ||
    alltrue([
      for subnet in local.subnet_ranges :
      !can(cidrnetmask(subnet.cidr)) || (
        subnet.start_num >= local.vpc_start_num &&
        subnet.end_num <= local.vpc_end_num
      )
    ])
  )
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
      condition = length(distinct(concat(
        var.public_subnet_cidrs,
        var.private_subnet_cidrs
        ))) == (
        length(var.public_subnet_cidrs) +
        length(var.private_subnet_cidrs)
      )
      error_message = "Subnet CIDR blocks must not be duplicated."
    }
    precondition {
      condition     = local.subnet_cidrs_are_within_vpc
      error_message = "Every subnet CIDR must be contained within the VPC CIDR."
    }

    precondition {
      condition     = local.subnet_cidrs_are_non_overlapping
      error_message = "Subnet CIDR blocks must not overlap."
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
