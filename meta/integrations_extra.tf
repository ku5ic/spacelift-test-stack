# Cloud integrations beyond AWS.
#
# GCP is the cheapest one to demo: Spacelift mints a dedicated service
# account for the stack and injects short-lived credentials, so nothing has
# to exist in GCP before the resource applies. You still have to grant that
# service account permissions in GCP before a run can do anything.
resource "spacelift_stack_gcp_service_account" "foundation" {
  count = var.enable_gcp_service_account ? 1 : 0

  stack_id     = spacelift_stack.foundation.id
  token_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
}

# Azure needs a real AAD tenant, and creating the integration leaves an
# app registration awaiting admin consent (admin_consent_url is exported
# for exactly that).
resource "spacelift_azure_integration" "test" {
  count = var.azure_tenant_id != "" ? 1 : 0

  name                    = "test-stack-azure-integration"
  tenant_id               = var.azure_tenant_id
  default_subscription_id = var.azure_subscription_id
  space_id                = spacelift_space.test_stack.id
  autoattach_enabled      = true
  labels                  = ["test-stack", "autoattach:azure"]
}
