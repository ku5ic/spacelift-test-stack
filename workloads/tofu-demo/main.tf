provider "aws" {
  region = var.aws_region
}

# Deliberately the same shape as workloads/app, so the only difference
# between the two stacks in the UI is the vendor: Terraform 1.5.7 there,
# OpenTofu here.

resource "aws_s3_object" "marker" {
  count = var.foundation_bucket_name != "" ? 1 : 0

  bucket  = var.foundation_bucket_name
  key     = "tofu-stack/marker.txt"
  content = "written by the OpenTofu stack"

  tags = {
    Environment = "test"
    ManagedBy   = "spacelift"
  }
}

resource "aws_ssm_parameter" "tofu_marker" {
  name  = "/${var.name_prefix}/tofu/workflow_tool"
  type  = "String"
  value = "opentofu"

  tags = {
    Environment = "test"
    ManagedBy   = "spacelift"
  }
}

# Cloud scanning can only match aws_s3_object and aws_ssm_parameter through the
# identity the provider writes to state; aws_sns_topic is one of the types it
# can also derive from attributes, so it exercises the second matching path.
resource "aws_sns_topic" "scan_marker" {
  name = "${var.name_prefix}-tofu-scan-marker"

  tags = {
    Environment = "test"
    ManagedBy   = "spacelift"
  }
}
