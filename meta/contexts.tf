# One shared Context mounted on all three stacks: exercises Contexts,
# Environment Variables and Context Attachments in one shot.

resource "spacelift_context" "common" {
  name        = "common-test-context"
  description = "Shared AWS region and naming prefix for every stack in this test setup"
}

resource "spacelift_environment_variable" "aws_region" {
  context_id  = spacelift_context.common.id
  name        = "TF_VAR_aws_region"
  value       = "eu-west-1"
  write_only  = false
  description = "Default region for every stack that mounts this context"
}

resource "spacelift_environment_variable" "name_prefix" {
  context_id  = spacelift_context.common.id
  name        = "TF_VAR_name_prefix"
  value       = "sk-spacelift-test"
  write_only  = false
  description = "Prefix applied to every resource name, keeps free-tier resources easy to find and tear down"
}

resource "spacelift_context_attachment" "foundation" {
  context_id = spacelift_context.common.id
  stack_id   = spacelift_stack.foundation.id
  priority   = 0
}

resource "spacelift_context_attachment" "app" {
  context_id = spacelift_context.common.id
  stack_id   = spacelift_stack.app.id
  priority   = 0
}

resource "spacelift_context_attachment" "ansible_config" {
  context_id = spacelift_context.common.id
  stack_id   = spacelift_stack.ansible_config.id
  priority   = 0
}
