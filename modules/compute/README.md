# Compute Module

Creates an EC2 instance and a dedicated security group.

## Features

- Configurable AMI and instance type
- Existing VPC and subnet integration
- Optional IAM instance profile
- Encrypted gp3 root volume
- IMDSv2 enforced
- Configurable ingress rules
- Resource tags
- Instance and security group outputs

## Scope

This module does not create a VPC, subnet, IAM role,
IAM instance profile, load balancer, or NAT gateway.

## Security

- Ingress is denied by default.
- Public IP assignment is disabled by default.
- EBS encryption is enabled.
- IMDSv2 is required.
- Review outbound rules before production use.