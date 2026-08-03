# Exercises the private Terraform Module Registry feature. This registers
# modules/s3-bucket in this same repo as a Spacelift-managed module. It is
# not consumed by workloads/foundation on purpose, so you can point the
# module's registry source at it from anywhere once it is testable in its
# own right.

resource "spacelift_module" "s3_bucket" {
  name               = "s3-bucket"
  repository         = var.vcs_repository
  branch             = var.vcs_branch
  project_root       = "modules/s3-bucket"
  terraform_provider = "aws"
  description        = "Reusable S3 bucket module, published to exercise the Module Registry"
}
