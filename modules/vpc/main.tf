data "aws_region" "current" {}

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

  nat_gateway_subnets = var.nat_gateway_mode == "single" ? {
    for index, subnet in local.public_subnets :
    index => subnet if index == "0"
  } : local.public_subnets

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
      condition = (
        length(var.public_subnet_cidrs) == length(var.availability_zones) &&
        length(var.private_subnet_cidrs) == length(var.availability_zones)
      )
      error_message = "Provide exactly one public and one private subnet CIDR per Availability Zone."
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


resource "aws_eip" "nat" {
  for_each = var.enable_nat_gateway ? local.nat_gateway_subnets : {}

  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.name}-nat-eip-${each.value.availability_zone}"
  })
}

resource "aws_nat_gateway" "this" {
  for_each = var.enable_nat_gateway ? local.nat_gateway_subnets : {}

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = merge(local.common_tags, {
    Name = "${var.name}-nat-${each.value.availability_zone}"
  })

  depends_on = [
    aws_internet_gateway.this
  ]
}

resource "aws_route" "private_nat" {
  for_each = var.enable_nat_gateway ? local.private_subnets : {}

  route_table_id = aws_route_table.private[each.key].id

  destination_cidr_block = "0.0.0.0/0"

  nat_gateway_id = var.nat_gateway_mode == "single" ? (
    aws_nat_gateway.this["0"].id
    ) : (
    aws_nat_gateway.this[each.key].id
  )
}

resource "aws_vpc_endpoint" "s3" {
  count = var.enable_s3_endpoint ? 1 : 0

  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = concat(
    [aws_route_table.public.id],
    [for route_table in aws_route_table.private : route_table.id]
  )

  tags = merge(local.common_tags, {
    Name = "${var.name}-s3-endpoint"
  })
}

locals {
  endpoint_client_cidrs = length(var.endpoint_allowed_cidrs) > 0 ? (
    var.endpoint_allowed_cidrs
  ) : var.private_subnet_cidrs
}

resource "aws_security_group" "vpc_endpoints" {
  for_each = (
    var.enable_ecr_endpoints ||
    var.enable_cloudwatch_logs_endpoint ||
    var.enable_sts_endpoint
  ) ? { enabled = true } : {}

  name_prefix = "${var.name}-vpce-"
  description = "Allow HTTPS from approved VPC clients to interface endpoints"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTPS from approved client CIDRs"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = local.endpoint_client_cidrs
  }

  egress {
    description = "Allow endpoint response traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.name}-vpce-sg"
  })
}

resource "aws_vpc_endpoint" "ecr_api" {
  count = var.enable_ecr_endpoints ? 1 : 0

  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type = "Interface"
  subnet_ids        = values(aws_subnet.private)[*].id
  security_group_ids = [
    aws_security_group.vpc_endpoints["enabled"].id
  ]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${var.name}-ecr-api-endpoint"
  })
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  count = var.enable_ecr_endpoints ? 1 : 0

  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type = "Interface"
  subnet_ids        = values(aws_subnet.private)[*].id
  security_group_ids = [
    aws_security_group.vpc_endpoints["enabled"].id
  ]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${var.name}-ecr-dkr-endpoint"
  })
}


resource "aws_vpc_endpoint" "cloudwatch_logs" {
  count = var.enable_cloudwatch_logs_endpoint ? 1 : 0

  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = values(aws_subnet.private)[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints["enabled"].id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${var.name}-cloudwatch-logs-endpoint"
  })
}

resource "aws_vpc_endpoint" "sts" {
  count = var.enable_sts_endpoint ? 1 : 0

  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.sts"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = values(aws_subnet.private)[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints["enabled"].id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${var.name}-sts-endpoint"
  })
}
