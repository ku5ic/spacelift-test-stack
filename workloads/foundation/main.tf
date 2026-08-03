provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "this" {
  bucket = "${var.name_prefix}-${random_id.suffix.hex}"

  tags = {
    Environment = "test"
    ManagedBy   = "spacelift"
  }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_role" "this" {
  name = "${var.name_prefix}-role-${random_id.suffix.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = data.aws_caller_identity.current.account_id }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Environment = "test"
    ManagedBy   = "spacelift"
  }
}

resource "aws_iam_role_policy" "bucket_access" {
  name = "bucket-access"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
      Resource = [aws_s3_bucket.this.arn, "${aws_s3_bucket.this.arn}/*"]
    }]
  })
}

resource "aws_ssm_parameter" "bucket_name" {
  name  = "/${var.name_prefix}/foundation/bucket_name"
  type  = "String"
  value = aws_s3_bucket.this.bucket

  tags = {
    Environment = "test"
    ManagedBy   = "spacelift"
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/${var.name_prefix}/foundation"
  retention_in_days = 7

  tags = {
    Environment = "test"
    ManagedBy   = "spacelift"
  }
}
