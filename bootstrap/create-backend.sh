#!/bin/bash
set -e

BUCKET_NAME="platform-tf-state-$(whoami)"  # make unique per user/account if shared
LOCK_TABLE="platform-tf-locks"
REGION="us-east-1"

echo "Creating S3 bucket: $BUCKET_NAME"
aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$REGION" || true

echo "Creating DynamoDB lock table"
aws dynamodb create-table \
  --table-name "$LOCK_TABLE" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$REGION" || true

echo "Done. Update backend.tf with your bucket name if customized."