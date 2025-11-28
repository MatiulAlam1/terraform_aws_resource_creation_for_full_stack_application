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
   - Default regions in `.regions` matrix: `eu-west-2`, `ap-northeast-1`
   - Can be overridden via `AWS_REGIONS` GitLab variable

## Region Sources

| File | Region Source | Default |
|------|---------------|---------|
| `terragrunt.hcl` | `get_env("AWS_REGION")` | `eu-west-2` |
| `environments/*/helm-apps/terragrunt.hcl` | `get_env("AWS_REGION")` | `eu-west-2` |
| `environments/*/vpc/terragrunt.hcl` | Dynamic AZ discovery | N/A |
| `.gitlab-ci.yml` | `.regions` matrix | `eu-west-2`, `ap-northeast-1` |

## How to Deploy to Different Regions

### Method 1: GitLab CI Variable
```
AWS_REGIONS = "eu-west-2,ap-northeast-1,af-south-1"
```

### Method 2: Update .gitlab-ci.yml
```yaml
.regions:
  dev: ["eu-west-2"]
  test: ["eu-west-2", "ap-northeast-1"]
  prod: ["eu-west-2", "ap-northeast-1", "af-south-1"]
```

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
1. Update GitLab variable: `AWS_REGIONS = "eu-west-2,ap-northeast-1,af-south-1"`
2. Run setup script: `bash scripts/setup-multi-region-backend.sh`
3. Deploy: `git push origin main`
