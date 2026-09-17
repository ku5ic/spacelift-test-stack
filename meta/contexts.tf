# Two contexts, attached two different ways:
#   common  -> explicit spacelift_context_attachment per stack, priority 0
#   hooks   -> autoattach: label, picked up by anything labelled test-stack
# Both sit in the parent space, so every child space inherits them.

resource "spacelift_context" "common" {
  name        = "common-test-context"
  description = "Shared AWS region and naming prefix for every stack in this test setup"
  space_id    = spacelift_space.test_stack.id
  labels      = ["test-stack"]
}

resource "spacelift_environment_variable" "aws_region" {
  context_id  = spacelift_context.common.id
  name        = "TF_VAR_aws_region"
  value       = var.aws_region
  write_only  = false
  description = "Default region for every stack that mounts this context"
}

resource "spacelift_environment_variable" "name_prefix" {
  context_id  = spacelift_context.common.id
  name        = "TF_VAR_name_prefix"
  value       = var.name_prefix
  write_only  = false
  description = "Prefix applied to every resource name, keeps free-tier resources easy to find and tear down"
}

# write_only hides the value in the UI and the API after creation - the
# Spacelift equivalent of a secret env var. Here purely so the masked
# rendering is visible somewhere.
#
# The value is a literal placeholder. write_only controls what Spacelift
# shows you after the fact; it does nothing about the value sitting in this
# file, which is public. Real secrets go in a tfvars file or an environment
# variable, never here.
resource "spacelift_environment_variable" "demo_masked" {
  context_id  = spacelift_context.common.id
  name        = "DEMO_MASKED_VALUE"
  value       = "placeholder-value-not-a-secret"
  write_only  = true
  description = "Write-only variable, here purely to show how masked values render once saved"
}

# Mounted files land on disk in the run's workspace at the given relative
# path, which is how you ship config files and credentials into a run.
resource "spacelift_mounted_file" "demo_config" {
  context_id    = spacelift_context.common.id
  relative_path = "demo/config.json"
  content       = base64encode(jsonencode({ source = "common-test-context", purpose = "mounted file demo" }))
  write_only    = false
  description   = "Readable mounted file, appears under /mnt/workspace/demo/config.json during a run"
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

resource "spacelift_context_attachment" "module" {
  context_id = spacelift_context.common.id
  module_id  = spacelift_module.s3_bucket.id
  priority   = 0
}

# Contexts carry lifecycle hooks too, which is the cleanest way to run the
# same commands across many stacks without a .spacelift/config.yml in each
# project root. This one autoattaches by label rather than by attachment
# resource - priority 10 so common's values win any collision.
resource "spacelift_context" "hooks" {
  name        = "shared-hooks-context"
  description = "Lifecycle hooks applied to every test-stack-labelled stack via autoattach"
  space_id    = spacelift_space.test_stack.id
  labels      = ["test-stack", "autoattach:test-stack"]

  before_init = ["echo \"[shared-hooks-context] before_init on $TF_VAR_name_prefix\""]
  before_plan = ["echo \"[shared-hooks-context] before_plan\""]
  after_plan  = ["echo \"[shared-hooks-context] after_plan\""]
  after_apply = ["echo \"[shared-hooks-context] after_apply\""]
  after_run   = ["echo \"[shared-hooks-context] after_run, runs on success and failure\""]
}
