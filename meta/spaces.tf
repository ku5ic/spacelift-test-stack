# Spaces give every other resource in this repo somewhere to live, and give
# the Spaces tree in the UI something to render. Children set
# inherit_entities so the shared context, policies and worker pool can sit
# once in the parent and still attach to stacks further down.

resource "spacelift_space" "test_stack" {
  name             = "test-stack"
  parent_space_id  = "root"
  description      = "Everything this playground creates lives under here"
  inherit_entities = true
  labels           = ["test-stack"]
}

resource "spacelift_space" "development" {
  name             = "test-stack-development"
  parent_space_id  = spacelift_space.test_stack.id
  description      = "The three core workload stacks"
  inherit_entities = true
  labels           = ["test-stack", "env:development"]
}

resource "spacelift_space" "staging" {
  name             = "test-stack-staging"
  parent_space_id  = spacelift_space.test_stack.id
  description      = "Alternative-vendor stacks (OpenTofu, Terragrunt, and the gated extras)"
  inherit_entities = true
  labels           = ["test-stack", "env:staging"]
}

resource "spacelift_space" "production" {
  name             = "test-stack-production"
  parent_space_id  = spacelift_space.test_stack.id
  description      = "Target space for blueprint-created stacks; deliberately left empty at apply time"
  inherit_entities = true
  labels           = ["test-stack", "env:production"]
}
