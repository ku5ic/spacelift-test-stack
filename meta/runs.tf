# Triggering runs and tasks from Terraform. Handy for seeding a fresh
# account so the Runs and Tasks views aren't empty, but it means `terraform
# apply` on meta/ starts touching AWS - hence off by default.
#
# When meta/ itself runs as a stack, this is a run triggering other runs.
# That is fine as long as it never targets meta/'s own stack: that recurses.
# `keepers` is what stops a re-trigger on every apply - it only fires again
# when the branch changes.

resource "spacelift_run" "foundation_bootstrap" {
  count = var.trigger_initial_runs ? 1 : 0

  stack_id = spacelift_stack.foundation.id
  proposed = false

  keepers = {
    branch = var.vcs_branch
  }

  depends_on = [
    spacelift_context_attachment.foundation,
    spacelift_aws_integration_attachment.foundation,
  ]
}

# A proposed run plans without applying, so this one is safe to leave on
# alongside the tracked run above.
resource "spacelift_run" "app_preview" {
  count = var.trigger_initial_runs ? 1 : 0

  stack_id = spacelift_stack.app.id
  proposed = true

  keepers = {
    branch = var.vcs_branch
  }
}

resource "spacelift_task" "foundation_state_list" {
  count = var.trigger_initial_runs ? 1 : 0

  stack_id = spacelift_stack.foundation.id
  command  = "terraform state list"
  init     = true

  depends_on = [spacelift_run.foundation_bootstrap]
}
