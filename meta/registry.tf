# The private registry: Terraform modules and Terraform providers, both
# published into the test-stack space.

resource "spacelift_module" "s3_bucket" {
  name               = "s3-bucket"
  repository         = var.vcs_repository
  branch             = var.vcs_branch
  project_root       = "modules/s3-bucket"
  terraform_provider = "aws"
  space_id           = spacelift_space.test_stack.id
  description        = "Reusable S3 bucket module, published to exercise the Module Registry"
  labels             = ["test-stack", "module"]

  # Modules run tests in their own sandbox stack; these mirror the stack
  # settings so the module's Tests tab behaves like a real stack.
  workflow_tool         = "TERRAFORM_FOSS"
  protect_from_deletion = false
  enable_local_preview  = true
  worker_pool_id        = var.attach_worker_pool ? spacelift_worker_pool.test.id : null
}

# A module version is normally cut by tagging the repo. Creating one from
# Terraform is useful when you want a specific commit published without a
# tag; leave var.module_version_number empty to stick to tag-driven
# versioning.
resource "spacelift_version" "s3_bucket" {
  count = var.module_version_number != "" ? 1 : 0

  module_id      = spacelift_module.s3_bucket.id
  version_number = var.module_version_number
  commit_sha     = var.module_version_commit_sha != "" ? var.module_version_commit_sha : null
}

# Private provider registry entry. Creating the entry is all Terraform can
# do - the actual provider binaries are pushed with `spacectl provider
# version create`, so this shows up as a provider with no versions yet.
resource "spacelift_terraform_provider" "demo" {
  # Provider type takes lowercase letters and numbers only - no hyphens.
  type        = "teststackdemo"
  space_id    = spacelift_space.test_stack.id
  description = "Placeholder private provider. Publish versions with `spacectl provider version create`."
  public      = false
  labels      = ["test-stack"]
}
