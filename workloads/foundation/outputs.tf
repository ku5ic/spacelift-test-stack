output "bucket_name" {
  value       = aws_s3_bucket.this.bucket
  description = "Consumed by the app and ansible-config stacks via spacelift_stack_dependency_reference"
}

output "iam_role_arn" {
  value = aws_iam_role.this.arn
}

output "ssm_parameter_name" {
  value = aws_ssm_parameter.bucket_name.name
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.this.name
}
