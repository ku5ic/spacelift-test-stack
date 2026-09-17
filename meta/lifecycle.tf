# Stack lifecycle controls.

# A disabled stack still exists and keeps its state, but stops reacting to
# pushes and schedules. Worth seeing once - the UI treats it differently
# everywhere it appears.
resource "spacelift_stack_activator" "kubernetes_disabled" {
  count = var.enable_extra_vendor_stacks ? 1 : 0

  stack_id = spacelift_stack.kubernetes[0].id
  enabled  = false
}

# The destructor turns `terraform destroy` on meta/ into a real teardown of
# the managed infrastructure: deleting the stack resource first triggers a
# destroy run on that stack. Without it, destroying meta/ deletes the
# Spacelift stacks and orphans everything they created in AWS.
#
# Off by default because it makes meta/'s destroy genuinely destructive.
resource "spacelift_stack_destructor" "foundation" {
  count = var.enable_stack_destructors ? 1 : 0

  stack_id     = spacelift_stack.foundation.id
  discard_runs = true

  # Ordering matters: app and ansible write into foundation's bucket, so
  # their destructors have to finish first.
  depends_on = [
    spacelift_stack_destructor.app,
    spacelift_stack_destructor.ansible_config,
  ]
}

resource "spacelift_stack_destructor" "app" {
  count = var.enable_stack_destructors ? 1 : 0

  stack_id     = spacelift_stack.app.id
  discard_runs = true
}

resource "spacelift_stack_destructor" "ansible_config" {
  count = var.enable_stack_destructors ? 1 : 0

  stack_id     = spacelift_stack.ansible_config.id
  discard_runs = true
}
