# Blueprints power the self-service "Create stack from blueprint" flow. Two
# here on purpose: one PUBLISHED so the form is usable, one DRAFT so the
# draft state is visible in the list.

resource "spacelift_blueprint" "workload_stack" {
  name        = "test-stack-workload-blueprint"
  description = "Self-service a copy of the foundation workload into any test-stack space"
  space       = spacelift_space.test_stack.id
  state       = "PUBLISHED"
  labels      = ["test-stack", "self-service"]

  template = templatefile("${path.module}/blueprints/workload-stack.yaml.tftpl", {
    space_id       = spacelift_space.production.id
    vcs_provider   = var.vcs_provider
    vcs_repository = var.vcs_repository
    vcs_branch     = var.vcs_branch
  })
}

resource "spacelift_blueprint" "draft" {
  name        = "test-stack-draft-blueprint"
  description = "Intentionally left in DRAFT so both blueprint states show up in the list"
  space       = spacelift_space.test_stack.id
  state       = "DRAFT"
  labels      = ["test-stack", "draft"]
}
