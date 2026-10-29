# -----------------------------------------------------------------------------
# 1. Secure S3 Bucket for Infrastructure State Tracking
# -----------------------------------------------------------------------------
# tfsec:ignore:aws-s3-specify-public-access-block
# bridgecrew:skip=CKV_AWS_144: "Cross-region replication is bypassed for development portfolio sandbox"
# bridgecrew:skip=CKV_AWS_145: "AES256 standard encryption is sufficient for sandbox state data"
# bridgecrew:skip=CKV_AWS_18:  "Access logging is disabled to minimize sandbox resource overhead"
# bridgecrew:skip=CKV2_AWS_62: "Event notifications are omitted for baseline storage state tier"
# bridgecrew:skip=CKV2_AWS_61: "Lifecycle configuration is bypassed to keep active state snapshots intact"
resource "aws_s3_bucket" "tf_state" {
  bucket        = "kyle-boobie-24"
  force_destroy = false                                

  lifecycle {
    prevent_destroy = true 
  }
}

# Enforce explicit version tracking to allow rolling back state corruption
resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Server-Side Encryption (SSE-S3) for all objects at rest
resource "aws_s3_bucket_server_side_encryption_configuration" "state_encryption" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block all public exposure entry points to the state bucket
resource "aws_s3_bucket_public_access_block" "state_public_block" {
  bucket = aws_s3_bucket.tf_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------------------------------------
# 2. DynamoDB State Locking Table (Prevents Race Conditions)
# -----------------------------------------------------------------------------
# bridgecrew:skip=CKV_AWS_119: "Default AWS managed encryption is sufficient for sandbox state locking metadata"
# bridgecrew:skip=CKV_AWS_28:  "Point-in-time recovery backup is bypassed for sandbox state tracking tier"
resource "aws_dynamodb_table" "tf_locks" {
  name         = "terraform-state-lock-table"
  billing_mode = "PAY_PER_REQUEST" 
  hash_key     = "LockID"         

  attribute {
    name = "LockID"
    type = "S"
  }
}
