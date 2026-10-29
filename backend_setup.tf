# Secure S3 Bucket for Infrastructure State Tracking
resource "aws_s3_bucket" "tf_state" {
  bucket        = "kyle-boobie-24" # Change this string to make it unique to you!
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

# DynamoDB State Locking Table (Prevents Concurrent Pipeline Collisions)
resource "aws_dynamodb_table" "tf_locks" {
  name         = "terraform-state-lock-table"
  billing_mode = "PAY_PER_REQUEST" 
  hash_key     = "LockID"         

  attribute {
    name = "LockID"
    type = "S"
  }
}
