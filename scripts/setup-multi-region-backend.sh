#!/bin/bash
set -e

# Multi-region backend setup script
# Creates S3 buckets and DynamoDB lock tables for each region

REGIONS="${AWS_REGIONS:-ap-south-1,us-east-1,eu-west-1}"

echo "🌍 Setting up Terraform backends for regions: $REGIONS"

IFS=',' read -ra REGION_ARRAY <<< "$REGIONS"

for REGION in "${REGION_ARRAY[@]}"; do
  echo ""
  echo "📦 Setting up backend in $REGION..."
  
  BUCKET_NAME="my-terraform-states-${REGION}"
  TABLE_NAME="terraform-locks-${REGION}"
  
  # Create S3 bucket
  echo "  Creating S3 bucket: $BUCKET_NAME"
  if aws s3api head-bucket --bucket "$BUCKET_NAME" --region "$REGION" 2>/dev/null; then
    echo "  ✅ Bucket already exists"
  else
    aws s3api create-bucket \
      --bucket "$BUCKET_NAME" \
      --region "$REGION" \
      $(if [ "$REGION" != "us-east-1" ]; then echo "--create-bucket-configuration LocationConstraint=$REGION"; fi)
    
    # Enable versioning
    aws s3api put-bucket-versioning \
      --bucket "$BUCKET_NAME" \
      --versioning-configuration Status=Enabled \
      --region "$REGION"
    
    # Enable encryption
    aws s3api put-bucket-encryption \
      --bucket "$BUCKET_NAME" \
      --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' \
      --region "$REGION"
    
    # Block public access
    aws s3api put-public-access-block \
      --bucket "$BUCKET_NAME" \
      --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
      --region "$REGION"
    
    echo "  ✅ Bucket created and configured"
  fi
  
  # Create DynamoDB table
  echo "  Creating DynamoDB table: $TABLE_NAME"
  if aws dynamodb describe-table --table-name "$TABLE_NAME" --region "$REGION" 2>/dev/null; then
    echo "  ✅ Table already exists"
  else
    aws dynamodb create-table \
      --table-name "$TABLE_NAME" \
      --attribute-definitions AttributeName=LockID,AttributeType=S \
      --key-schema AttributeName=LockID,KeyType=HASH \
      --billing-mode PAY_PER_REQUEST \
      --region "$REGION"
    
    echo "  ⏳ Waiting for table to be active..."
    aws dynamodb wait table-exists --table-name "$TABLE_NAME" --region "$REGION"
    echo "  ✅ Table created"
  fi
done

echo ""
echo "✅ Multi-region backend setup complete!"
echo ""
echo "📋 Summary:"
for REGION in "${REGION_ARRAY[@]}"; do
  echo "  Region: $REGION"
  echo "    S3 Bucket: my-terraform-states-${REGION}"
  echo "    DynamoDB Table: terraform-locks-${REGION}"
done
