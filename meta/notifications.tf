# Optional webhooks, only created if var.notification_webhook_url is set.

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
