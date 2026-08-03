provider "aws" {
  region = var.aws_region
}

resource "aws_s3_object" "marker" {
  bucket  = var.foundation_bucket_name
  key     = "app-stack/marker.txt"
  content = "written by the app stack, proving the foundation -> app stack dependency works"

  tags = {
    Environment = "test"
    ManagedBy   = "spacelift"
  }
}

resource "aws_ssm_parameter" "app_marker" {
  name  = "/${var.name_prefix}/app/foundation_role_arn"
  type  = "String"
  value = var.foundation_role_arn != "" ? var.foundation_role_arn : "not-set-yet"

  tags = {
    Environment = "test"
    ManagedBy   = "spacelift"
  }
}
