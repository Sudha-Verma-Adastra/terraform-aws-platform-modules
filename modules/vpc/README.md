# AWS VPC Module

Creates a VPC with public and private subnets across multiple Availability Zones.

## Features

- VPC DNS support and DNS hostnames
- Internet Gateway
- Public and private subnets
- Public route table with an Internet Gateway default route
- Separate private route tables without a default internet route
- Resource tagging
- Input validation and reusable outputs

## Security Notes

- Public subnets enable public IPv4 assignment on launch, but this alone does
  not make a workload reachable; routing and security-group rules also matter.
- Private subnets do not automatically receive public IPv4 addresses.
- Private route tables have no default internet route.
- This module does not create NAT Gateways, security groups, NACL customizations,
  VPC endpoints, or workload resources.

## Inputs

| Name | Description |
|---|---|
| name | Resource name prefix |
| vpc_cidr | VPC IPv4 CIDR |
| availability_zones | At least two unique Availability Zones |
| public_subnet_cidrs | One CIDR per Availability Zone |
| private_subnet_cidrs | One CIDR per Availability Zone |
| tags | Additional tags |

## Outputs

- `vpc_id`
- `vpc_cidr`
- `internet_gateway_id`
- `public_subnet_ids`
- `private_subnet_ids`
- `public_route_table_id`
- `private_route_table_ids`
- `availability_zones`

## Usage

See the root example configuration once the example is implemented.
