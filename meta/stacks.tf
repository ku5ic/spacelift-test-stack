# The three core stacks: two Terraform, one native Ansible. Between them
# they turn on most of the per-stack toggles the UI exposes, so the Stack
# Settings screens have something other than defaults to show.

resource "spacelift_stack" "foundation" {
  name         = "test-stack-foundation"
  description  = "AWS free-tier-safe baseline: S3 bucket, IAM role, SSM parameter, CloudWatch log group"
  repository   = var.vcs_repository
  branch       = var.vcs_branch
  project_root = "workloads/foundation"
  space_id     = spacelift_space.development.id

  terraform_version       = "1.5.7"
  terraform_workflow_tool = "TERRAFORM_FOSS"
  terraform_workspace     = "default"
  autodeploy              = false
  labels                  = ["test-stack", "foundation", "aws"]

  # Every other stack in the repo depends on this one, so it gets the
  # protective settings: deletion guard on, outputs readable by the other
  # stacks, state values sanitized in logs.
  protect_from_deletion            = true
  terraform_external_state_access  = true
  terraform_smart_sanitization     = true
  enable_well_known_secret_masking = true
  enable_local_preview             = true
  worker_pool_id                   = var.attach_worker_pool ? spacelift_worker_pool.test.id : null

  # autoretry re-queues a run that a newer commit invalidated. Left off so
  # a failed run stays on screen long enough to read.
  autoretry = false
}

resource "spacelift_stack" "app" {
  name         = "test-stack-app"
  description  = "Depends on foundation's outputs; writes an object into the foundation bucket"
  repository   = var.vcs_repository
  branch       = var.vcs_branch
  project_root = "workloads/app"
  space_id     = spacelift_space.development.id

  terraform_version       = "1.5.7"
  terraform_workflow_tool = "TERRAFORM_FOSS"
  autodeploy              = false
  labels                  = ["test-stack", "app", "aws"]

  # Run promotion lets a proposed run's plan be promoted straight to an
  # apply from the run screen, instead of re-planning on the tracked run.
  allow_run_promotion  = true
  enable_local_preview = true

  # Pulls the shared module's sources into the workspace as well, so an
  # edit under modules/ shows up in this stack's diff.
  additional_project_globs = ["modules/s3-bucket/**"]

  worker_pool_id = var.attach_worker_pool ? spacelift_worker_pool.test.id : null
}

resource "spacelift_stack" "ansible_config" {
  name         = "test-stack-ansible-config"
  description  = "Native Ansible stack, also depends on foundation's outputs"
  repository   = var.vcs_repository
  branch       = var.vcs_branch
  project_root = "workloads/ansible-config"
  space_id     = spacelift_space.development.id

  autodeploy = false
  labels     = ["test-stack", "ansible"]

  worker_pool_id = var.attach_worker_pool ? spacelift_worker_pool.test.id : null

  ansible {
    playbook = "playbook.yml"
  }
}
