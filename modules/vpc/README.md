# AWS VPC Module

Creates a reusable AWS VPC with public and private subnets across multiple Availability Zones.

## Features

- VPC DNS support and DNS hostnames.
- Internet Gateway.
- Public and private subnets across multiple Availability Zones.
- Public route table with an IPv4 default route targeting the Internet Gateway.
- Dedicated private route tables and subnet associations.
- Input validation and resource tagging.
- Reusable outputs for downstream modules.

## Network Design

```text
VPC
├── Internet Gateway
├── Public route table
│   └── 0.0.0.0/0 -> Internet Gateway
├── Public subnet(s)
│   └── Associated with the public route table
└── Private subnet(s)
    └── Dedicated private route table(s)
        └── No default internet route configured by this module
```

## Security Notes

- Public subnet address assignment alone does not make workloads reachable; routing, security groups, network ACLs, and service configuration also matter.
- Private subnets do not automatically assign public IPv4 addresses on launch.
- The module does not configure a NAT Gateway or VPC endpoints.
- Private route tables have no default internet route configured by this module.
- Review the actual Terraform configuration and plan before deployment.

## Inputs

| Name | Description |
|---|---|
| `name` | Resource name prefix; must not be empty |
| `vpc_cidr` | VPC IPv4 CIDR |
| `availability_zones` | At least two unique Availability Zones |
| `public_subnet_cidrs` | Public subnet CIDRs, one per Availability Zone |
| `private_subnet_cidrs` | Private subnet CIDRs, one per Availability Zone |
| `tags` | Additional resource tags |

CIDR validation checks valid CIDR notation, duplicate subnet CIDRs, subnet containment within the VPC, and overlapping subnet ranges.

## Outputs

- `vpc_id`
- `vpc_cidr`
- `internet_gateway_id`
- `public_subnet_ids`
- `private_subnet_ids`
- `public_route_table_id`
- `private_route_table_ids`
- `availability_zones`

## Testing

Run from the repository root:

```bash
terraform -chdir=modules/vpc fmt -check
terraform -chdir=modules/vpc init -backend=false
terraform -chdir=modules/vpc validate
terraform -chdir=modules/vpc test
```

**Latest result:** 13 tests passed, 0 failed, 0 skipped, as reported during local development.

The suite uses Terraform's native test framework with a mocked AWS provider and plan-based tests. It validates module configuration and selected design properties without deploying infrastructure to AWS.

### Test coverage

- Valid multi-AZ VPC configuration.
- Invalid VPC and subnet CIDRs.
- Mismatched subnet counts.
- Duplicate subnet CIDRs and Availability Zones.
- Public/private network design.
- Subnet containment and CIDR overlap checks.
- Public default-route destination and Internet Gateway target.
- Private route-table collection structure and subnet associations.
- Private subnet public-IP assignment settings.

Note: collection-key and association checks do not independently prove the absence of every possible Internet Gateway route. Review the private route-table resources and routes for that property.

## Troubleshooting

See [`../../docs/vpc-troubleshooting.md`](../../docs/vpc-troubleshooting.md) for development errors, fixes, and validation results.
