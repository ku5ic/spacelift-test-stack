output "foundation_stack_id" {
  value = spacelift_stack.foundation.id
}

output "app_stack_id" {
  value = spacelift_stack.app.id
}

output "ansible_stack_id" {
  value = spacelift_stack.ansible_config.id
}

output "context_id" {
  value = spacelift_context.common.id
}

output "aws_integration_id" {
  value = spacelift_aws_integration.test.id
}
