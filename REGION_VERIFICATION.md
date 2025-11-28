# Region Configuration Verification

## ✅ All Hardcoded Regions Removed

### Changes Made

1. **Root terragrunt.hcl**
   - Default region: `eu-west-2` (London)
   - Reads from `AWS_REGION` environment variable

2. **All VPC Configurations** (dev/test/prod)
   - Removed hardcoded `azs` parameter
   - Now uses `az_count = 3` with dynamic AZ discovery

3. **All Helm-Apps Configurations** (dev/test/prod)
   - Removed hardcoded `--region ap-south-1`
   - Now uses `${local.region}` from environment variable

4. **GitLab CI Pipeline**
   - Uses branch-based region selection via `AWS_REGIONS_DEV`, `AWS_REGIONS_TEST`, `AWS_REGIONS_PROD`
   - No hardcoded regions in pipeline

## Region Sources

| File | Region Source | Default |
|------|---------------|---------|
| `terragrunt.hcl` | `get_env("AWS_REGION")` | `eu-west-2` |
| `environments/*/helm-apps/terragrunt.hcl` | `get_env("AWS_REGION")` | `eu-west-2` |
| `environments/*/vpc/terragrunt.hcl` | Dynamic AZ discovery | N/A |
| `.gitlab-ci.yml` | Branch-based variables | `AWS_REGIONS_DEV/TEST/PROD` |

## How to Deploy to Different Regions

### Method 1: GitLab CI Variables
```
AWS_REGIONS_DEV = "eu-west-2"
AWS_REGIONS_TEST = "eu-west-2,ap-northeast-1"
AWS_REGIONS_PROD = "eu-west-2,ap-northeast-1,af-south-1"
```

### Method 2: Branch-Based Deployment
Pipeline automatically selects regions based on branch:
- `dev` branch → `AWS_REGIONS_DEV`
- `test` branch → `AWS_REGIONS_TEST`
- `main` branch → `AWS_REGIONS_PROD`

### Method 3: Local Deployment
```bash
export AWS_REGION="af-south-1"
cd environments/dev
terragrunt run-all apply
```

## Verification Commands

```bash
# Check for any remaining hardcoded regions in code
grep -r "ap-south-1\|us-east-1\|eu-west-1" --include="*.hcl" --include="*.tf" --exclude-dir=".terragrunt-cache" .

# Should return empty (no hardcoded regions)
```

## Default Region Rationale

**London (eu-west-2)** chosen as default because:
- User requested London and Japan deployment
- London is first in alphabetical order
- Provides good latency for Europe
- Can be easily overridden via environment variable

## Adding New Regions

No code changes needed! Just:
1. Update GitLab variables: `AWS_REGIONS_DEV`, `AWS_REGIONS_TEST`, `AWS_REGIONS_PROD`
2. Run setup script: `bash scripts/setup-multi-region-backend.sh`
3. Deploy: `git push origin main`
