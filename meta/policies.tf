# Six policy types attached across the three stacks. engine_type defaults to
# the current Rego engine on the provider; set explicitly if your account
# still runs the older engine (see docs.spacelift.io/concepts/policy).

resource "spacelift_policy" "login" {
  name        = "restrict-login-to-test-team"
  description = "Only members of the configured team may log in; verify input.session shape against docs before relying on this"
  type        = "LOGIN"
  body        = file("${path.module}/policies/login.rego")
}
# LOGIN policies are account-wide and cannot be attached to a specific
# stack or module, no policy_attachment resource exists for it.

resource "spacelift_policy" "plan_required_tags" {
  name   = "require-environment-tag"
  type   = "PLAN"
  body   = file("${path.module}/policies/plan-required-tags.rego")
  labels = ["test-stack"]
}

resource "spacelift_policy_attachment" "plan_required_tags_foundation" {
  policy_id = spacelift_policy.plan_required_tags.id
  stack_id  = spacelift_stack.foundation.id
}

resource "spacelift_policy_attachment" "plan_required_tags_app" {
  policy_id = spacelift_policy.plan_required_tags.id
  stack_id  = spacelift_stack.app.id
}

resource "spacelift_policy" "plan_protect_destroy" {
  name = "protect-bucket-from-destroy"
  type = "PLAN"
  body = file("${path.module}/policies/plan-protect-destroy.rego")
}

resource "spacelift_policy_attachment" "plan_protect_destroy_foundation" {
  policy_id = spacelift_policy.plan_protect_destroy.id
  stack_id  = spacelift_stack.foundation.id
}

resource "spacelift_policy" "approval_production" {
  name        = "require-approval-before-apply"
  description = "Requires a manual approval before app can apply; verify input.session shape against docs before relying on this"
  type        = "APPROVAL"
  body        = file("${path.module}/policies/approval-production.rego")
}

resource "spacelift_policy_attachment" "approval_production_app" {
  policy_id = spacelift_policy.approval_production.id
  stack_id  = spacelift_stack.app.id
}

resource "spacelift_policy" "task_restrict" {
  name = "restrict-task-commands"
  type = "TASK"
  body = file("${path.module}/policies/task-restrict.rego")
}

resource "spacelift_policy_attachment" "task_restrict_foundation" {
  policy_id = spacelift_policy.task_restrict.id
  stack_id  = spacelift_stack.foundation.id
}

resource "spacelift_policy" "notification_failures_only" {
  name        = "notify-on-failed-runs-only"
  description = "Verify the notification rule name (webhook/slack/custom) against docs.spacelift.io/concepts/policy/notification-policy for your account"
  type        = "NOTIFICATION"
  body        = file("${path.module}/policies/notification-failures-only.rego")

  # NOTIFICATION policies can't use spacelift_policy_attachment (same
  # restriction as LOGIN); they attach via the autoattach: label
  # convention instead. foundation and app both carry the "aws" label,
  # ansible_config doesn't, so this matches only those two stacks.
  labels = ["autoattach:aws"]
}

resource "spacelift_policy" "trigger_dependents" {
  name        = "trigger-app-after-foundation"
  description = "Older alternative to the native stack_dependency wiring in dependencies.tf; kept disabled by default, see the rego body"
  type        = "TRIGGER"
  body        = file("${path.module}/policies/trigger-on-foundation-success.rego")
}

resource "spacelift_policy_attachment" "trigger_dependents_foundation" {
  policy_id = spacelift_policy.trigger_dependents.id
  stack_id  = spacelift_stack.foundation.id
}
