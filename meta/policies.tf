# Eight policies covering every attachable policy type the provider accepts
# (ACCESS, APPROVAL, GIT_PUSH, LOGIN, PLAN, TRIGGER, NOTIFICATION) plus the
# APPROVAL-based replacement for the deprecated TASK type.
#
# engine_type defaults to REGO_V0 on the provider and every body here is
# written in v0 syntax (no `if`, no `contains`). Set engine_type = "REGO_V1"
# and rewrite the bodies if you want to exercise the newer engine.
#
# LOGIN and NOTIFICATION policies cannot take a spacelift_policy_attachment:
# LOGIN is account-wide, NOTIFICATION attaches via autoattach: labels.

locals {
  # Every stack a stack-scoped policy should cover.
  policy_target_stacks = {
    foundation = spacelift_stack.foundation.id
    app        = spacelift_stack.app.id
    ansible    = spacelift_stack.ansible_config.id
    tofu       = spacelift_stack.tofu.id
    terragrunt = spacelift_stack.terragrunt.id
  }
}

resource "spacelift_policy" "login" {
  name        = "restrict-login-to-test-team"
  description = "Only members of the configured team may log in; verify input.session shape against docs before relying on this"
  type        = "LOGIN"
  body        = file("${path.module}/policies/login.rego")
  labels      = ["test-stack"]
}

resource "spacelift_policy" "access" {
  name        = "stack-access-team-scoped"
  description = "ACCESS policy: any logged-in user can read, admins and the test team can write"
  type        = "ACCESS"
  body        = file("${path.module}/policies/access-team-scoped.rego")
  # ACCESS is a legacy policy type: the API rejects it in any space but root.
  space_id = "root"
  labels   = ["test-stack"]
}

resource "spacelift_policy_attachment" "access_foundation" {
  policy_id = spacelift_policy.access.id
  stack_id  = spacelift_stack.foundation.id
}

resource "spacelift_policy" "git_push" {
  name        = "trigger-only-on-project-root-changes"
  description = "GIT_PUSH policy: track on the stack's branch, propose elsewhere, ignore pushes that miss the project root"
  type        = "GIT_PUSH"
  body        = file("${path.module}/policies/git-push-project-scoped.rego")
  space_id    = spacelift_space.test_stack.id
  labels      = ["test-stack"]
}

resource "spacelift_policy_attachment" "git_push" {
  for_each = local.policy_target_stacks

  policy_id = spacelift_policy.git_push.id
  stack_id  = each.value
}

resource "spacelift_policy" "plan_required_tags" {
  name     = "require-environment-tag"
  type     = "PLAN"
  body     = file("${path.module}/policies/plan-required-tags.rego")
  space_id = spacelift_space.test_stack.id
  labels   = ["test-stack"]
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
  name     = "protect-bucket-from-destroy"
  type     = "PLAN"
  body     = file("${path.module}/policies/plan-protect-destroy.rego")
  space_id = spacelift_space.test_stack.id
  labels   = ["test-stack"]
}

resource "spacelift_policy_attachment" "plan_protect_destroy_foundation" {
  policy_id = spacelift_policy.plan_protect_destroy.id
  stack_id  = spacelift_stack.foundation.id
}

resource "spacelift_policy" "approval_production" {
  name        = "require-approval-before-apply"
  description = "Requires one approval and zero rejections before app can apply"
  type        = "APPROVAL"
  body        = file("${path.module}/policies/approval-production.rego")
  space_id    = spacelift_space.test_stack.id
  labels      = ["test-stack"]
}

resource "spacelift_policy_attachment" "approval_production_app" {
  policy_id = spacelift_policy.approval_production.id
  stack_id  = spacelift_stack.app.id
}

resource "spacelift_policy" "task_restrict" {
  name        = "restrict-task-commands"
  description = "Migrated off the deprecated TASK type; blocks destroy / state rm run commands"
  type        = "APPROVAL"
  body        = file("${path.module}/policies/task-restrict.rego")
  space_id    = spacelift_space.test_stack.id
  labels      = ["test-stack"]
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
  space_id    = spacelift_space.test_stack.id

  # NOTIFICATION policies can't use spacelift_policy_attachment (same
  # restriction as LOGIN); they attach via the autoattach: label
  # convention instead. foundation, app, tofu and terragrunt carry the
  # "aws" label, the Ansible stack doesn't.
  labels = ["autoattach:aws"]
}

resource "spacelift_policy" "trigger_dependents" {
  name        = "trigger-app-after-foundation"
  description = "Older alternative to the native stack_dependency wiring in dependencies.tf; kept disabled in the rego body"
  type        = "TRIGGER"
  body        = file("${path.module}/policies/trigger-on-foundation-success.rego")
  space_id    = spacelift_space.test_stack.id
  labels      = ["test-stack"]
}

resource "spacelift_policy_attachment" "trigger_dependents_foundation" {
  policy_id = spacelift_policy.trigger_dependents.id
  stack_id  = spacelift_stack.foundation.id
}
