provider "spacelift" {}

# Authentication:
# - If this configuration is applied FROM WITHIN a Spacelift run (the
#   self-managing pattern), SPACELIFT_API_TOKEN is injected automatically
#   once the stack has a role attachment. No further config needed.
# - If applied locally to bootstrap the account for the first time, export
#   SPACELIFT_API_KEY_ENDPOINT, SPACELIFT_API_KEY_ID and
#   SPACELIFT_API_KEY_SECRET from an administrative API key created in
#   Organization Settings > API Keys.
