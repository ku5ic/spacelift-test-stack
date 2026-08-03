# AWS Cloud Integration: Spacelift assumes var.aws_iam_role_arn via STS and
# injects temporary credentials into runs on the attached stacks. Create the
# IAM role manually first (README > AWS integration) to avoid the circular
# dependency between the integration's generated external ID and the role's
# trust policy.

resource "spacelift_aws_integration" "test" {
  name                            = "test-stack-aws-integration"
  role_arn                        = var.aws_iam_role_arn
  generate_credentials_in_worker  = false
  duration_seconds                = 1800
  labels                          = ["test-stack"]
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
