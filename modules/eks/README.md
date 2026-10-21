# Terraform AWS EKS Module

Creates an Amazon EKS cluster and an EKS managed node group.

## Resources

- EKS control plane
- EKS managed node group
- Cluster IAM role and policy attachment
- Worker-node IAM role and policy attachments
- EKS control-plane logging configuration

## Prerequisites

- An AWS provider configured by the root module.
- At least two suitable subnets in different Availability Zones for the EKS cluster.
- At least two suitable subnets for the managed worker nodes.
- An EKS Kubernetes version supported in the selected AWS region.
- Appropriate permissions to create EKS, IAM, EC2 networking and related resources.

## Networking considerations

The module does not create a VPC or subnets. Pass subnet IDs from the VPC module.

Private worker nodes need a path to required AWS services. Depending on the architecture, this may require NAT gateways or VPC endpoints for services such as ECR, S3, STS and other required APIs.

Private-only Kubernetes API access means administrators and automation must have network connectivity to the VPC.

## Security considerations

- The Kubernetes API endpoint is private by default.
- If public endpoint access is enabled, specify restrictive public_access_cidrs.
- Cluster creation grants the creating principal initial administrative access.
  Review access configuration before production use.
- The node role uses AWS managed policies for worker-node operation, ECR pulls and CNI networking.
- For stronger workload-level isolation, consider moving CNI permissions to a dedicated role and using EKS Pod Identity or IAM Roles for Service Accounts where appropriate.
- Five control-plane log types are enabled. Review CloudWatch Logs retention and cost requirements.

## Inputs

| Name | Description | Default |
|---|---|---|
| cluster_name | EKS cluster name | Required |
| cluster_version | Kubernetes major.minor version | Required |
| cluster_subnet_ids | Control-plane subnet IDs | Required |
| node_subnet_ids | Worker-node subnet IDs | Required |
| endpoint_private_access | Private API endpoint access | true |
| endpoint_public_access | Public API endpoint access | false |
| public_access_cidrs | Allowed public endpoint CIDRs | [] |
| node_group_name | Managed node group name | default |
| instance_types | Worker EC2 instance types | ["t3.medium"] |
| capacity_type | ON_DEMAND or SPOT | ON_DEMAND |
| min_size | Minimum worker count | 1 |
| desired_size | Desired worker count | 2 |
| max_size | Maximum worker count | 3 |
| disk_size | Worker root disk in GiB | 20 |
| tags | Additional tags | {} |

## Outputs

- cluster_name
- cluster_arn
- cluster_endpoint
- cluster_certificate_authority_data
- cluster_iam_role_arn
- node_iam_role_arn
- node_group_name
- node_group_arn

## Validation

Run from the repository root:

```bash
terraform -chdir=modules/eks init -backend=false
terraform -chdir=modules/eks fmt -check
terraform -chdir=modules/eks validate
terraform -chdir=modules/eks test