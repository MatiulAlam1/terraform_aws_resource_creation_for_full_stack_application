# Vertical Scaling Guide

## Pre-Scaling Checklist

```bash
# 1. Always run plan first
cd environments/prod
terragrunt run-all plan

# 2. Look for these symbols:
#   ~ modify   = Safe (no data loss)
#   -/+ replace = DANGER (data loss)

# 3. Check specific resource
cd environments/prod/rds
terragrunt plan | grep -E "must be replaced|will be replaced"
```

## RDS Scaling (✅ Safe)

### Instance Class
```hcl
# environments/prod/rds/terragrunt.hcl
rds_instance_class = "db.t4g.medium"  # from db.t4g.small
```

**Result**: Modify in-place, 5-10 min downtime, no data loss

### Storage
```hcl
rds_storage = 50  # from 20
```

**Result**: Modify in-place, no downtime, no data loss

**Note**: Storage can only increase, never decrease

## MSK Scaling (✅ Safe)

### Broker Instance Type
```hcl
# environments/prod/msk/terragrunt.hcl
broker_instance_type = "kafka.m5.large"  # from kafka.t3.small
```

**Result**: Rolling update, no downtime, no data loss

### Volume Size
```hcl
broker_volume_size = 100  # from 10
```

**Result**: Modify in-place, no downtime, no data loss

## MQ Scaling (⚠️ DANGER - Recreates)

### Instance Type
```hcl
# environments/prod/mq/terragrunt.hcl
instance_type = "mq.m5.large"  # from mq.t3.micro
```

**Result**: ❌ REPLACE - All messages lost!

### Safe MQ Scaling Procedure

```bash
# 1. Stop message producers
kubectl scale deployment producer --replicas=0

# 2. Drain queues (wait for consumers to process)
# Monitor: RabbitMQ Management Console

# 3. Verify queues empty
# Check message count = 0

# 4. Apply scaling
cd environments/prod/mq
terragrunt apply

# 5. Restart producers
kubectl scale deployment producer --replicas=3
```

## ElastiCache Scaling

### Node Type
```hcl
# environments/prod/elasticache/terragrunt.hcl
node_type = "cache.m5.large"  # from cache.t4g.small
```

**Result**: 
- Single node: ❌ REPLACE (data loss)
- Cluster mode: ✅ MODIFY (no data loss)

**Current setup**: Single node (dev/test/prod)
**Recommendation**: Use cluster mode for prod

## EKS Scaling

### Node Instance Type
```hcl
# environments/prod/eks/terragrunt.hcl
node_instance_types = ["t3.large"]  # from ["t3.small"]
```

**Result**: ✅ New node group created, old drained, no data loss

### Node Count
```hcl
node_min_size     = 3  # from 2
node_max_size     = 5  # from 3
node_desired_size = 3  # from 2
```

**Result**: ✅ Modify in-place, no downtime

## Terraform Plan Symbols

```
~ modify in-place
  Resource will be updated without replacement
  ✅ Safe - No data loss

-/+ destroy and then create replacement
  Resource will be destroyed and recreated
  ❌ DANGER - Data loss possible

+ create
  New resource will be created
  ✅ Safe

- destroy
  Resource will be destroyed
  ⚠️ Check if intentional
```

## Example Plan Output

### Safe Modification
```
# module.rds[0].aws_db_instance.this will be updated in-place
~ resource "aws_db_instance" "this" {
    ~ instance_class = "db.t4g.small" -> "db.t4g.medium"
  }
```

### Dangerous Replacement
```
# aws_mq_broker.mq must be replaced
-/+ resource "aws_mq_broker" "mq" {
    ~ host_instance_type = "mq.t3.micro" -> "mq.m5.large" # forces replacement
  }
```

## Best Practices

1. **Always run plan first**: `terragrunt plan`
2. **Check for replacements**: Look for `-/+` symbol
3. **Backup before scaling**: 
   - RDS: Automated snapshots enabled
   - MSK: Kafka replication handles this
   - MQ: Drain queues first
4. **Scale during maintenance window**: Minimize user impact
5. **Test in dev/test first**: Verify behavior
6. **Monitor after scaling**: Check application metrics

## Rollback Procedure

### If scaling fails:

```bash
# 1. Check Terraform state
terragrunt show

# 2. Rollback code change
git revert HEAD

# 3. Apply previous configuration
terragrunt apply

# 4. For RDS: Restore from snapshot if needed
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier my-rds-restored \
  --db-snapshot-identifier <snapshot-id>
```

## Cost Implications

| Change | Cost Impact |
|--------|-------------|
| RDS: `db.t4g.small` → `db.t4g.medium` | +100% |
| MSK: `kafka.t3.small` → `kafka.m5.large` | +400% |
| MQ: `mq.t3.micro` → `mq.m5.large` | +1000% |
| EKS: `t3.small` → `t3.large` | +100% per node |

Use AWS Pricing Calculator: https://calculator.aws
