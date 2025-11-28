# Multi-Region Deployment Guide

## Overview

This infrastructure supports multi-region deployment with region-specific state management. Each region has its own S3 bucket and DynamoDB lock table for Terraform state.

## Architecture

- **Region Configuration**: Dynamic via `AWS_REGION` environment variable
- **State Management**: Region-specific S3 buckets (`my-terraform-states-{region}`)
- **State Locking**: Region-specific DynamoDB tables (`terraform-locks-{region}`)
- **No Global Tables**: Each region maintains independent state (no DynamoDB global tables needed)

## Setup Instructions

### 1. Configure Regions in GitLab CI/CD Variables

Add the following variables in GitLab: **Settings → CI/CD → Variables**

```
AWS_REGIONS = "ap-south-1,us-east-1,eu-west-1"
```

Or override the `.regions` matrix in `.gitlab-ci.yml`:

```yaml
.regions:
  dev: ["ap-south-1"]
  test: ["ap-south-1", "us-east-1"]
  prod: ["ap-south-1", "us-east-1", "eu-west-1"]
```

### 2. Initialize Backend Infrastructure

Run the setup script to create S3 buckets and DynamoDB tables in all regions:

```bash
# Set regions (comma-separated)
export AWS_REGIONS="ap-south-1,us-east-1,eu-west-1"

# Run setup script
bash scripts/setup-multi-region-backend.sh
```

This creates:
- S3 bucket: `my-terraform-states-{region}` (versioned, encrypted, private)
- DynamoDB table: `terraform-locks-{region}` (PAY_PER_REQUEST billing)

### 3. Deploy to Specific Region

```bash
# Set target region
export AWS_REGION="us-east-1"

# Deploy
cd environments/dev
terragrunt run-all apply
```

### 4. Deploy to Multiple Regions (GitLab CI)

Push to branch and GitLab CI will automatically deploy to all configured regions in parallel:

```bash
git add .
git commit -m "Deploy to multi-region"
git push origin main  # Deploys to all prod regions
```

## How It Works

### Dynamic Region Selection

**Root terragrunt.hcl**:
```hcl
locals {
  region = get_env("AWS_REGION", "ap-south-1")
}

remote_state {
  backend = "s3"
  config = {
    bucket         = "my-terraform-states-${local.region}"
    region         = local.region
    dynamodb_table = "terraform-locks-${local.region}"
  }
}
```

### Dynamic Availability Zones

**VPC Module** automatically selects AZs based on region:
```hcl
data "aws_availability_zones" "available" {
  state = "available"
}

azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)
```

### GitLab CI Parallel Deployment

```yaml
terragrunt-apply-prod:
  parallel:
    matrix:
      - AWS_REGION: !reference [.regions, prod]
  script:
    - export AWS_DEFAULT_REGION="$AWS_REGION"
    - terragrunt run-all apply
```

## State Management

### Why No DynamoDB Global Tables?

- Each region's infrastructure is **independent**
- Terraform state is **region-specific**
- No need for cross-region state replication
- Simpler architecture, lower cost

### State File Structure

```
s3://my-terraform-states-ap-south-1/
  └── environments/dev/vpc/terraform.tfstate
  └── environments/dev/eks/terraform.tfstate
  └── ...

s3://my-terraform-states-us-east-1/
  └── environments/dev/vpc/terraform.tfstate
  └── environments/dev/eks/terraform.tfstate
  └── ...
```

## Region-Specific Configuration

### Different VPC CIDRs per Region

Edit `environments/{env}/vpc/terragrunt.hcl`:

```hcl
locals {
  region = get_env("AWS_REGION", "ap-south-1")
  
  vpc_cidrs = {
    "ap-south-1" = "10.0.0.0/16"
    "us-east-1"  = "10.1.0.0/16"
    "eu-west-1"  = "10.2.0.0/16"
  }
}

inputs = {
  vpc_cidr = local.vpc_cidrs[local.region]
  # ...
}
```

### Different Instance Sizes per Region

```hcl
locals {
  region = get_env("AWS_REGION", "ap-south-1")
  
  instance_types = {
    "ap-south-1" = "t3.small"
    "us-east-1"  = "t3.medium"
    "eu-west-1"  = "t3.large"
  }
}

inputs = {
  instance_type = local.instance_types[local.region]
}
```

## Deployment Strategies

### Strategy 1: Sequential Region Deployment

Deploy one region at a time:

```bash
for region in ap-south-1 us-east-1 eu-west-1; do
  export AWS_REGION=$region
  cd environments/prod
  terragrunt run-all apply --terragrunt-non-interactive
done
```

### Strategy 2: Parallel Region Deployment (GitLab CI)

Automatic parallel deployment via GitLab CI matrix jobs.

### Strategy 3: Blue-Green Multi-Region

1. Deploy to new region (e.g., `eu-west-1`)
2. Test and validate
3. Update DNS/Route53 to include new region
4. Decommission old region if needed

## Monitoring Multi-Region Deployments

### Check All Regions

```bash
for region in ap-south-1 us-east-1 eu-west-1; do
  echo "=== Region: $region ==="
  aws eks list-clusters --region $region
  aws rds describe-db-instances --region $region --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus]'
done
```

### GitLab CI Observability

Each region gets its own observability job that checks:
- EKS cluster health
- RDS instance status
- Drift detection
- Security posture

## Cost Optimization

- **Dev**: Single region (`ap-south-1`)
- **Test**: Two regions for testing failover
- **Prod**: Three regions for high availability

## Troubleshooting

### State Bucket Not Found

```bash
# Verify bucket exists
aws s3 ls s3://my-terraform-states-$AWS_REGION --region $AWS_REGION

# Create if missing
bash scripts/setup-multi-region-backend.sh
```

### Wrong Region Deployed

```bash
# Check current region
echo $AWS_REGION

# Verify state file location
terragrunt output
```

### Lock Table Issues

```bash
# Check lock table
aws dynamodb describe-table --table-name terraform-locks-$AWS_REGION --region $AWS_REGION

# Force unlock if stuck
terragrunt force-unlock <LOCK_ID>
```

## Best Practices

1. **Always set AWS_REGION** before running Terragrunt
2. **Use GitLab CI variables** for region configuration
3. **Test in dev/test regions** before prod
4. **Monitor state bucket sizes** and enable lifecycle policies
5. **Use different VPC CIDRs** per region to avoid conflicts
6. **Enable VPC peering** if cross-region communication needed
7. **Use Route53** for multi-region DNS failover

## Security

- All S3 buckets have public access blocked
- Versioning enabled for state recovery
- Encryption at rest (AES256)
- DynamoDB tables use on-demand billing
- Each region isolated by default

## Next Steps

- Set up Route53 health checks for multi-region failover
- Configure VPC peering between regions
- Implement cross-region RDS read replicas
- Set up CloudWatch cross-region dashboards
