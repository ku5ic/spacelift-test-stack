# Everything on the stack Scheduling tab: drift detection, scheduled runs,
# scheduled tasks and stack TTL.

# Drift detection runs a proposed run on a cron and flags resources that
# changed outside Spacelift. reconcile = true would auto-apply the fix; left
# off so drift shows up as a finding instead of silently healing.
resource "spacelift_drift_detection" "foundation" {
  stack_id     = spacelift_stack.foundation.id
  schedule     = ["0 7 * * *"]
  timezone     = "Europe/Zagreb"
  reconcile    = false
  ignore_state = false
}

resource "spacelift_drift_detection" "tofu" {
  stack_id  = spacelift_stack.tofu.id
  schedule  = ["*/30 * * * *"]
  timezone  = "UTC"
  reconcile = true
}

# A scheduled run is a full tracked run on a cron. runtime_config lets the
# scheduled run differ from the stack's normal settings - here it pins a
# runner image for the nightly run only.
resource "spacelift_scheduled_run" "app_nightly" {
  stack_id = spacelift_stack.app.id
  name     = "nightly-app-run"
  every    = ["0 3 * * *"]
  timezone = "Europe/Zagreb"

  runtime_config {
    project_root = "workloads/app"
    runner_image = "public.ecr.aws/spacelift/runner-terraform:latest"
  }
}

# A scheduled task runs a one-off command on the stack's workspace, outside
# the plan/apply flow. This one is deliberately harmless.
resource "spacelift_scheduled_task" "foundation_state_list" {
  stack_id = spacelift_stack.foundation.id
  command  = "terraform state list"
  every    = ["0 6 * * 1"]
  timezone = "Europe/Zagreb"
}

# Stack TTL: deletes the stack (and optionally its resources) at a fixed
# unix timestamp. There is no sane default for "when", so this only exists
# once you set var.scheduled_delete_at.
resource "spacelift_scheduled_delete_stack" "tofu_ttl" {
  count = var.scheduled_delete_at > 0 ? 1 : 0

  stack_id         = spacelift_stack.tofu.id
  at               = var.scheduled_delete_at
  delete_resources = true
}
