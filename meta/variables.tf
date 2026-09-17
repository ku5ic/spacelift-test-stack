# Required: the two things that can't be guessed.

variable "vcs_repository" {
  description = "owner/repo of this repository as registered in Spacelift's VCS integration"
  type        = string
}

variable "aws_iam_role_arn" {
  description = "ARN of a pre-created AWS IAM role that Spacelift assumes via the AWS cloud integration. Create it manually first, see README > Bootstrapping."
  type        = string
}

# Defaults that are safe to leave alone.

variable "vcs_branch" {
  description = "Branch every stack in this test setup tracks"
  type        = string
  default     = "main"
}

variable "vcs_provider" {
  description = "VCS provider slug used in the blueprint body. One of GITHUB, GITLAB, BITBUCKET_CLOUD, BITBUCKET_DATACENTER, GITHUB_ENTERPRISE, AZURE_DEVOPS."
  type        = string
  default     = "GITHUB"
}

variable "aws_region" {
  description = "Region injected into every stack via the common context"
  type        = string
  default     = "eu-west-1"
}

variable "name_prefix" {
  description = "Prefix on every AWS resource name, so free-tier leftovers are easy to find"
  type        = string
  default     = "sk-spacelift-test"
}

# Opt-in features. Everything below is off by default because it either
# costs money, needs infrastructure this repo can't create, or changes
# account-wide behaviour.

variable "attach_worker_pool" {
  description = "Point every stack at the private worker pool. Runs queue forever unless a launcher is actually running against it."
  type        = bool
  default     = false
}

variable "enable_extra_vendor_stacks" {
  description = "Create the Pulumi, CloudFormation and Kubernetes stacks. They exist to populate the UI; their runs won't go green without the backing infrastructure."
  type        = bool
  default     = false
}

variable "pulumi_login_url" {
  description = "Pulumi state backend URL, e.g. s3://my-bucket. Only read when enable_extra_vendor_stacks is true."
  type        = string
  default     = "s3://replace-me-pulumi-state"
}

variable "cloudformation_template_bucket" {
  description = "Existing S3 bucket the AWS integration can write CloudFormation templates into. Only read when enable_extra_vendor_stacks is true."
  type        = string
  default     = "replace-me-cfn-templates"
}

variable "enable_stack_destructors" {
  description = "Make `terraform destroy` on meta/ also destroy the AWS resources the workload stacks created. Genuinely destructive."
  type        = bool
  default     = false
}

variable "trigger_initial_runs" {
  description = "Trigger a tracked run on foundation, a proposed run on app, and a task, straight from this apply. Seeds the Runs views on a fresh account."
  type        = bool
  default     = false
}

variable "enable_gcp_service_account" {
  description = "Mint a Spacelift-managed GCP service account for the foundation stack"
  type        = bool
  default     = false
}

variable "scheduled_delete_at" {
  description = "Unix timestamp at which the OpenTofu stack and its resources are deleted. 0 disables the TTL."
  type        = number
  default     = 0
}

variable "module_version_number" {
  description = "Semver to publish for the s3-bucket module, e.g. 0.1.0. Empty means versions come from git tags instead."
  type        = string
  default     = ""
}

variable "module_version_commit_sha" {
  description = "Commit to publish the module version from. Empty uses the branch head."
  type        = string
  default     = ""
}

# External endpoints and identities.

variable "notification_webhook_url" {
  description = "Endpoint for per-stack webhooks and the named webhook the notification policy targets. https://webhook.site gives you one instantly."
  type        = string
  default     = ""
}

variable "audit_trail_webhook_url" {
  description = "Endpoint that receives every audit trail event for the account"
  type        = string
  default     = ""
}

variable "webhook_secret" {
  description = "Shared secret used to sign webhook deliveries. No default on purpose - this repo is public, and a committed default is a published secret. Empty means deliveries go unsigned."
  type        = string
  default     = ""
  sensitive   = true
}

variable "security_email" {
  description = "Account-wide security contact. Empty leaves the account setting untouched."
  type        = string
  default     = ""
}

variable "default_runner_image" {
  description = "Account-wide default runner image. Empty leaves the account setting untouched."
  type        = string
  default     = ""
}

variable "idp_group_name" {
  description = "SSO group name to map onto the test-stack spaces. Needs SSO configured; empty skips the mapping."
  type        = string
  default     = ""
}

variable "invited_username" {
  description = "Username for the invited user. Only used when invited_user_email is set."
  type        = string
  default     = "test-stack-guest"
}

variable "invited_user_email" {
  description = "Email to send a Spacelift invitation to. Empty skips the invite."
  type        = string
  default     = ""
}

variable "azure_tenant_id" {
  description = "Azure AD tenant ID. Empty skips the Azure integration."
  type        = string
  default     = ""
}

variable "azure_subscription_id" {
  description = "Default Azure subscription for the integration"
  type        = string
  default     = ""
}

# Self-management. See meta/self_management.tf for the import-first flow.

variable "manage_meta_stack" {
  description = "Adopt the administrative stack that runs meta/ into this configuration. Import it first, or the apply tries to create a duplicate."
  type        = bool
  default     = false
}

variable "meta_stack_name" {
  description = "Name of the administrative stack running meta/. Must match the stack you created in the UI."
  type        = string
  default     = "test-stack-meta"
}
