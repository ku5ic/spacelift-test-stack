# Account-wide settings. Both of these affect every stack in the account,
# not just this playground's, so they only exist once you opt in.

resource "spacelift_security_email" "test" {
  count = var.security_email != "" ? 1 : 0
  email = var.security_email
}

# Overrides the runner image for every stack that doesn't set its own.
resource "spacelift_default_runner_image" "test" {
  count  = var.default_runner_image != "" ? 1 : 0
  public = var.default_runner_image
}
