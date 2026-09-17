# Three different webhook mechanisms, which are easy to confuse:
#
#   spacelift_webhook             per-stack, fires on that stack's run state changes
#   spacelift_named_webhook       account/space-scoped endpoint, addressed by
#                                 NOTIFICATION policies via endpoint_id
#   spacelift_audit_trail_webhook one per account, receives every audit event
#
# All of them need somewhere to POST to, so all of them are gated on a URL
# variable. https://webhook.site gives you a throwaway endpoint in one click.

resource "spacelift_webhook" "foundation" {
  count    = var.notification_webhook_url != "" ? 1 : 0
  stack_id = spacelift_stack.foundation.id
  endpoint = var.notification_webhook_url
  enabled  = true
}

resource "spacelift_webhook" "app" {
  count    = var.notification_webhook_url != "" ? 1 : 0
  stack_id = spacelift_stack.app.id
  endpoint = var.notification_webhook_url
  enabled  = true
}

resource "spacelift_named_webhook" "notifications" {
  count = var.notification_webhook_url != "" ? 1 : 0

  name             = "test-stack-notifications"
  endpoint         = var.notification_webhook_url
  space_id         = spacelift_space.test_stack.id
  enabled          = true
  retry_on_failure = true
  labels           = ["test-stack"]
  secret           = var.webhook_secret != "" ? var.webhook_secret : null
}

# Secret headers are attached to a named webhook and sent with every
# delivery; the value is write-only once saved.
resource "spacelift_named_webhook_secret_header" "notifications_auth" {
  count = var.notification_webhook_url != "" && var.webhook_secret != "" ? 1 : 0

  webhook_id = spacelift_named_webhook.notifications[0].id
  key        = "X-Test-Stack-Token"
  value      = var.webhook_secret
}

resource "spacelift_audit_trail_webhook" "test" {
  count = var.audit_trail_webhook_url != "" ? 1 : 0

  endpoint         = var.audit_trail_webhook_url
  enabled          = true
  include_runs     = true
  retry_on_failure = true
  secret           = var.webhook_secret != "" ? var.webhook_secret : null
  custom_headers   = { "X-Test-Stack-Source" = "spacelift-test-stack" }
}
