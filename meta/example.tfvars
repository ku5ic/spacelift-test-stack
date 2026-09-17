# Copy to terraform.tfvars and fill in. Only the first two are required.

vcs_repository   = "your-org/spacelift-test-stack"
aws_iam_role_arn = "arn:aws:iam::123456789012:role/spacelift-test-stack"

# vcs_branch   = "main"
# vcs_provider = "GITHUB"
# aws_region   = "eu-west-1"
# name_prefix  = "sk-spacelift-test"

# Feature flags, all off by default. variables.tf says what each one costs.
# attach_worker_pool         = false
# enable_extra_vendor_stacks = false
# enable_stack_destructors   = false
# trigger_initial_runs       = false
# enable_gcp_service_account = false
# scheduled_delete_at        = 0

# A throwaway endpoint from https://webhook.site lights up the per-stack
# webhooks, the named webhook, and the notification policy's webhook rule.
# notification_webhook_url = ""
# audit_trail_webhook_url  = ""

# Signs webhook deliveries. Has no default - a default in a public repo is a
# published secret. Leave empty and deliveries go unsigned.
# webhook_secret = ""

# Account-wide: affects stacks outside this playground too.
# security_email       = ""
# default_runner_image = ""

# Need SSO / an invite flow / an Azure tenant.
# idp_group_name        = ""
# invited_user_email    = ""
# azure_tenant_id       = ""
# azure_subscription_id = ""
