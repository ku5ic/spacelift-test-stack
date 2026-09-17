# Closing the loop: the administrative stack that runs this directory,
# declared in the directory it runs.
#
# It cannot be created by its own first apply - something has to exist
# before it can manage itself - so the flow is create-then-adopt:
#
#   1. Create the stack by hand in the UI (project root `meta`,
#      Administrative = true) and let it apply once with this flag off.
#   2. On that stack, run a task:
#        terraform import 'spacelift_stack.meta[0]' <the stack's slug>
#   3. Set TF_VAR_manage_meta_stack=true on the stack's Environment tab and
#      trigger a run. The plan should show no changes to this resource.
#
# Skipping the import and flipping the flag straight to true makes the apply
# try to create a second stack with the same name, which fails. That's the
# safe failure, but it's still a failed run.
#
# protect_from_deletion is on because deleting this stack orphans every
# other resource in this configuration.

resource "spacelift_stack" "meta" {
  count = var.manage_meta_stack ? 1 : 0

  name         = var.meta_stack_name
  description  = "Administrative stack that applies meta/ - manages every other Spacelift resource in this repo"
  repository   = var.vcs_repository
  branch       = var.vcs_branch
  project_root = "meta"
  space_id     = "root"

  # The provider deprecates `administrative` in favour of attaching a role
  # with space-admin actions to the stack (see rbac.tf for that pattern).
  # Not migrated here on purpose: flipping this off during an apply revokes
  # the SPACELIFT_API_TOKEN the very run is using to make the change. Do
  # that migration from a second stack, or from your laptop, never from this
  # stack's own run.
  administrative = true

  autodeploy            = false
  protect_from_deletion = true
  labels                = ["test-stack", "administrative"]

  # terraform_version is left unset on purpose: it's computed, so the stack
  # keeps whatever version you picked in the UI instead of the import
  # immediately showing a diff.
}
