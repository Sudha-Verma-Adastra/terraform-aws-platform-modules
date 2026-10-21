
## `docs/eks-troubleshooting.md`

```markdown
# EKS Module Troubleshooting Log

Record the actual command, complete error message, suspected root cause, change,
validation result and final outcome for each issue. Do not mark an issue resolved
until the relevant test or AWS-side validation succeeds.

## Issue 1: Unsupported Kubernetes version

**Symptom:** EKS rejects the requested Kubernetes version.

**Possible cause:** The selected version is not supported in the target region,
or is no longer available for new clusters.

**Investigation:**
1. Confirm the configured cluster_version.
2. Check current EKS version availability for the target region.
3. Confirm that the AWS provider version supports the selected configuration.

**Resolution:** Use a currently supported version and rerun validation and plan.

**Status:** Not yet verified against AWS.

## Issue 2: Worker nodes fail to join the cluster

**Possible causes:**
- Incorrect node IAM role or missing required permissions.
- Worker nodes cannot reach the Kubernetes API endpoint.
- Private subnets lack required outbound connectivity or VPC endpoints.
- Incorrect subnet selection, DNS or security-group configuration.

**Investigation:**
1. Inspect EKS node-group health issues.
2. Check the node IAM role and attached policies.
3. Verify subnet routes, DNS and security-group connectivity.
4. Check EKS control-plane logs and relevant EC2 instance status.

**Resolution:** Apply only the change supported by the observed error, then verify node
group health and Kubernetes node registration.

**Status:** Not yet verified against AWS.

## Issue 3: Kubernetes API endpoint is unreachable

**Possible causes:**
- Private endpoint enabled but the client is outside the VPC.
- Missing VPN, Direct Connect, bastion or other approved network path.
- Incorrect public endpoint CIDRs when public access is enabled.
- DNS or security-group connectivity problems.

**Investigation:**
1. Check endpoint_private_access and endpoint_public_access.
2. Verify the client network route and DNS resolution.
3. Confirm the client source IP is permitted when public access is used.

**Resolution:** Restore an approved network path. Do not open the endpoint to
0.0.0.0/0 as a troubleshooting shortcut.

**Status:** Not yet verified against AWS.

## Issue 4: Worker nodes cannot pull container images

**Possible causes:**
- Missing ECR permissions.
- No route to ECR or S3 image layers.
- Required VPC endpoints or NAT connectivity are missing.
- Incorrect DNS or security-group rules.

**Investigation:**
1. Inspect pod events for image-pull errors.
2. Verify node IAM permissions.
3. Check the route tables and required AWS service endpoints.

**Resolution:** Correct the IAM or network configuration identified by the evidence.

**Status:** Not yet verified against AWS.

## Issue 5: Terraform test or validation fails

**Investigation:**
1. Capture the complete Terraform error.
2. Run terraform fmt -check and terraform validate.
3. Confirm the Terraform CLI and AWS provider versions.
4. Fix the smallest reproducible issue and rerun the affected test.

**Status:** Awaiting first local test run.

## Troubleshooting entry template

### Issue:
- Date:
- Command:
- Exact error:
- Suspected root cause:
- Change made:
- Validation command:
- Validation result:
- Final outcome:
- Status: Open / Verified / Closed