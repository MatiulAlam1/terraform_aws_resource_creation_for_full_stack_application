# Deployment Approval Strategy (2025 Best Practices)

## Current Implementation

| Environment | Approval | Rationale |
|-------------|----------|-----------|
| **Dev** | ✅ Auto-approve | Fast iteration, low risk |
| **Test** | ✅ Auto-approve | CI/CD efficiency, automated testing |
| **Prod** | ⚠️ **Manual approval** | Safety gate, compliance, change control |

## Why This Approach?

### Dev: Auto-Approve ✅
```yaml
when: automatic  # Default behavior
```

**Benefits**:
- Fast feedback loop for developers
- Encourages experimentation
- No bottlenecks in development cycle
- Low blast radius (isolated environment)

**Risk**: Low - Dev environment is disposable

### Test: Auto-Approve ✅
```yaml
when: automatic  # Default behavior
```

**Benefits**:
- Enables true CI/CD automation
- Automated integration tests run immediately
- Validates changes before prod
- Catches issues early

**Risk**: Low-Medium - Test environment mirrors prod but not customer-facing

### Prod: Manual Approval ⚠️
```yaml
when: manual  # Requires human approval
```

**Benefits**:
- **Human oversight** before production changes
- **Change control** compliance (SOC2, ISO 27001)
- **Review window** for plan inspection
- **Rollback decision point**
- **Audit trail** (who approved, when)

**Risk**: High - Customer-facing, revenue impact

## 2025 DevOps Best Practices

### ✅ DO: Progressive Delivery

```
Dev (auto) → Test (auto) → Prod (manual) → Prod Rollout (canary/blue-green)
```

### ✅ DO: Automated Gates Before Manual Approval

Pipeline already includes:
1. ✅ Secrets scan (Gitleaks)
2. ✅ IaC security scan (Checkov, tfsec)
3. ✅ Policy checks on plan
4. ✅ Drift detection

**Only after all automated checks pass** → Manual approval

### ✅ DO: Time-Boxed Approvals

```yaml
# Add to prod job (optional)
environment:
  name: production/$AWS_REGION
  action: start
  deployment_tier: production
  # Auto-expire approval after 24 hours
```

### ❌ DON'T: Auto-Approve Prod Without Safeguards

**Bad practice**:
```yaml
# NEVER do this for prod
terragrunt-apply-prod:
  when: automatic  # ❌ No human oversight
```

**Exceptions** (when auto-approve prod is acceptable):
- Hotfix deployments (with proper alerting)
- Rollback operations (automated)
- Non-breaking changes (feature flags)

## Advanced: Conditional Auto-Approve

For mature teams with strong automation:

```yaml
terragrunt-apply-prod:
  when: manual
  rules:
    # Auto-approve for minor changes
    - if: '$CI_COMMIT_MESSAGE =~ /\[auto-deploy\]/'
      when: automatic
    # Auto-approve for specific paths
    - if: '$CI_PIPELINE_SOURCE == "schedule"'
      when: automatic
    # Default: manual
    - when: manual
```

## Approval Workflow

### Current Flow

```
1. Developer pushes to main
2. Pipeline runs: scan → validate → security → plan
3. ⏸️  Pipeline PAUSES at apply stage
4. Reviewer checks:
   - Plan output
   - Security scan results
   - Change scope
5. ✅ Reviewer clicks "Play" button in GitLab
6. Deployment proceeds to all prod regions
```

### Who Should Approve?

**Recommended approvers**:
- Platform/DevOps team lead
- SRE on-call
- Release manager
- Senior engineer (for infrastructure changes)

**GitLab Configuration**:
```yaml
# Settings → CI/CD → Protected Environments
# production/* → Allowed to deploy: Maintainers only
```

## Metrics to Track

```yaml
# Add to observability stage
deployment-metrics:
  stage: observability
  script:
    - |
      echo "Deployment Metrics:"
      echo "Time to approve: $(($(date +%s) - $CI_PIPELINE_CREATED_AT))"
      echo "Approver: $GITLAB_USER_NAME"
      echo "Changes: $(git diff --stat HEAD~1)"
```

## Emergency Procedures

### Hotfix (Skip Manual Approval)

```bash
# Option 1: Use GitLab API
curl --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.com/api/v4/projects/$CI_PROJECT_ID/jobs/$CI_JOB_ID/play"

# Option 2: Add [hotfix] tag
git commit -m "[hotfix] Critical security patch"
# Pipeline auto-approves based on tag
```

### Rollback (Auto-Approve)

```yaml
rollback-prod:
  stage: apply
  when: manual
  script:
    - git revert HEAD
    - terragrunt apply -auto-approve  # Safe: reverting to known good state
```

## Compliance Requirements

### SOC2 / ISO 27001
- ✅ Manual approval for prod: **Required**
- ✅ Audit trail: GitLab provides (who, when, what)
- ✅ Separation of duties: Developer ≠ Approver

### HIPAA / PCI-DSS
- ✅ Change control process: Manual approval
- ✅ Review before deployment: Plan inspection
- ✅ Rollback capability: Git revert + manual trigger

## Alternative: Approval via Merge Request

**Even better approach**:

```yaml
# Require MR approval before merge to main
# Settings → Repository → Merge request approvals
# Minimum approvals: 2
# Eligible approvers: Maintainers

# Then auto-deploy after merge
terragrunt-apply-prod:
  when: automatic  # Safe because MR was approved
  only:
    - main
```

**Benefits**:
- Code review + infrastructure review in one step
- Approval happens before pipeline runs
- Better audit trail (MR comments, discussions)

## Recommendation

**Current setup is OPTIMAL for 2025**:
- Dev/Test: Auto-approve (speed)
- Prod: Manual approval (safety)
- All environments: Automated security gates

**Next steps to enhance**:
1. Add deployment windows (only deploy during business hours)
2. Implement canary deployments (gradual rollout)
3. Add automatic rollback on failure
4. Integrate with incident management (PagerDuty, Opsgenie)

## Summary

```
✅ Dev:  Auto-approve (fast iteration)
✅ Test: Auto-approve (CI/CD efficiency)
⚠️  Prod: Manual approval (safety + compliance)
```

This balances **speed** (dev/test) with **safety** (prod) - the gold standard for 2025 DevOps.
