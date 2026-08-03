variable "vcs_repository" {
  description = "owner/repo of this repository as registered in Spacelift's VCS integration (e.g. github.com org/repo)"
  type        = string
}

variable "vcs_branch" {
  description = "Branch every stack in this test setup tracks"
  type        = string
  default     = "main"
}

variable "aws_iam_role_arn" {
  description = "ARN of a pre-created AWS IAM role that Spacelift will assume via the AWS cloud integration. Create this manually first, see README > AWS integration."
  type        = string
}

variable "notification_webhook_url" {
  description = "Endpoint that receives failed-run notifications. Leave empty to skip creating webhooks."
  type        = string
  default     = ""
}
