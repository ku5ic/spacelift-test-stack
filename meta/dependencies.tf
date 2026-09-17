# Stack Dependencies: app and ansible-config both consume foundation's
# outputs. This is the modern mechanism for chaining runs and passing data
# between stacks, including across tools (Terraform -> Ansible here).

resource "spacelift_stack_dependency" "app_on_foundation" {
  stack_id            = spacelift_stack.app.id
  depends_on_stack_id = spacelift_stack.foundation.id
}

resource "spacelift_stack_dependency_reference" "bucket_name_to_app" {
  stack_dependency_id = spacelift_stack_dependency.app_on_foundation.id
  output_name         = "bucket_name"
  input_name          = "TF_VAR_foundation_bucket_name"
}

resource "spacelift_stack_dependency_reference" "role_arn_to_app" {
  stack_dependency_id = spacelift_stack_dependency.app_on_foundation.id
  output_name         = "iam_role_arn"
  input_name          = "TF_VAR_foundation_role_arn"
}

resource "spacelift_stack_dependency" "ansible_on_foundation" {
  stack_id            = spacelift_stack.ansible_config.id
  depends_on_stack_id = spacelift_stack.foundation.id
}

resource "spacelift_stack_dependency_reference" "bucket_name_to_ansible" {
  stack_dependency_id = spacelift_stack_dependency.ansible_on_foundation.id
  output_name         = "bucket_name"
  input_name          = "FOUNDATION_BUCKET_NAME"
}

# The OpenTofu stack joins the same graph, so the dependency view has more
# than a single fan-out to draw.
resource "spacelift_stack_dependency" "tofu_on_foundation" {
  stack_id            = spacelift_stack.tofu.id
  depends_on_stack_id = spacelift_stack.foundation.id
}

resource "spacelift_stack_dependency_reference" "bucket_name_to_tofu" {
  stack_dependency_id = spacelift_stack_dependency.tofu_on_foundation.id
  output_name         = "bucket_name"
  input_name          = "TF_VAR_foundation_bucket_name"
}

# And terragrunt hangs off the OpenTofu stack rather than foundation, which
# makes the graph two levels deep instead of flat.
resource "spacelift_stack_dependency" "terragrunt_on_tofu" {
  stack_id            = spacelift_stack.terragrunt.id
  depends_on_stack_id = spacelift_stack.tofu.id
}
