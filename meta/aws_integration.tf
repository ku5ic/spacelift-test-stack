# AWS Cloud Integration: Spacelift assumes var.aws_iam_role_arn via STS and
# injects temporary credentials into runs on the attached stacks. Create the
# IAM role manually first (README > Bootstrapping) to avoid the circular
# dependency between the integration's generated external ID and the role's
# trust policy.

resource "spacelift_aws_integration" "test" {
  name                           = "test-stack-aws-integration"
  role_arn                       = var.aws_iam_role_arn
  space_id                       = spacelift_space.test_stack.id
  generate_credentials_in_worker = false
  duration_seconds               = 1800
  region                         = var.aws_region
  tag_assume_role                = true
  labels                         = ["test-stack"]

  # Leave autoattach off: the explicit attachments below are what make the
  # integration's Attached stacks list interesting to look at.
  autoattach_enabled = false
}

resource "spacelift_aws_integration_attachment" "foundation" {
  integration_id = spacelift_aws_integration.test.id
  stack_id       = spacelift_stack.foundation.id
  read           = true
  write          = true
}

resource "spacelift_aws_integration_attachment" "app" {
  integration_id = spacelift_aws_integration.test.id
  stack_id       = spacelift_stack.app.id
  read           = true
  write          = true
}

resource "spacelift_aws_integration_attachment" "ansible_config" {
  integration_id = spacelift_aws_integration.test.id
  stack_id       = spacelift_stack.ansible_config.id
  read           = true
  write          = true
}

resource "spacelift_aws_integration_attachment" "tofu" {
  integration_id = spacelift_aws_integration.test.id
  stack_id       = spacelift_stack.tofu.id
  read           = true
  write          = true
}

resource "spacelift_aws_integration_attachment" "terragrunt" {
  integration_id = spacelift_aws_integration.test.id
  stack_id       = spacelift_stack.terragrunt.id
  read           = true
  write          = true
}

# Modules get credentials too - the module's test runs need them to plan
# against a real account.
resource "spacelift_aws_integration_attachment" "module" {
  integration_id = spacelift_aws_integration.test.id
  module_id      = spacelift_module.s3_bucket.id
  read           = true
  write          = false
}
