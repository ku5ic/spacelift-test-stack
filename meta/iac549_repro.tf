# Repro for IAC-549: 45 planned changes so the run Changes view has more than one page.
locals {
  iac549_batches = {
    bulk9 = 45
  }

  iac549_stacks = merge([
    for prefix, n in local.iac549_batches : {
      for i in range(1, n + 1) :
      format("%s-%04d", prefix, i) => {}
    }
  ]...)
}

resource "spacelift_stack" "iac549_bulk" {
  for_each   = local.iac549_stacks
  name       = each.key
  repository = var.vcs_repository
  branch     = var.vcs_branch
  space_id   = spacelift_space.test_stack.id
}
