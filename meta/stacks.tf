# Three stacks exercising Spacelift's multi-IaC support: two Terraform
# stacks with a real dependency between them, plus one native Ansible stack.

resource "spacelift_stack" "foundation" {
  name         = "test-stack-foundation"
  description  = "AWS free-tier-safe baseline: S3 bucket, IAM role, SSM parameter, CloudWatch log group"
  repository   = var.vcs_repository
  branch       = var.vcs_branch
  project_root = "workloads/foundation"

  terraform_version = "1.5.7"
  autodeploy         = false
  labels             = ["test-stack", "foundation", "aws"]
}

resource "spacelift_stack" "app" {
  name         = "test-stack-app"
  description  = "Depends on foundation's outputs; writes an object into the foundation bucket"
  repository   = var.vcs_repository
  branch       = var.vcs_branch
  project_root = "workloads/app"

  terraform_version = "1.5.7"
  autodeploy         = false
  labels             = ["test-stack", "app", "aws"]
}

resource "spacelift_stack" "ansible_config" {
  name         = "test-stack-ansible-config"
  description  = "Native Ansible stack, also depends on foundation's outputs"
  repository   = var.vcs_repository
  branch       = var.vcs_branch
  project_root = "workloads/ansible-config"

  autodeploy = false
  labels     = ["test-stack", "ansible"]

  # NOTE: verify this block's exact name and arguments against the current
  # spacelift-io/spacelift provider docs before the first apply. The registry
  # docs render client-side and could not be scraped verbatim while drafting
  # this scaffold. The Spacelift UI confirms an Ansible vendor with a
  # "Playbook" field when creating a stack manually (Create stack > vendor
  # config); this block is the provider-managed equivalent. If it does not
  # match, create this one stack manually in the UI instead and leave it out
  # of this file, everything else (context, dependency, policies) still
  # applies to it by stack_id once created.
  ansible {
    playbook = "playbook.yml"
  }
}
