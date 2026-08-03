variable "aws_region" {
  description = "Injected via the common context as TF_VAR_aws_region"
  type        = string
  default     = "eu-west-1"
}

variable "name_prefix" {
  description = "Injected via the common context as TF_VAR_name_prefix"
  type        = string
  default     = "sk-spacelift-test"
}

variable "foundation_bucket_name" {
  description = "Populated by the Spacelift stack dependency from foundation's bucket_name output. Empty default lets `terraform validate` and local plans succeed outside Spacelift."
  type        = string
  default     = ""
}

variable "foundation_role_arn" {
  description = "Populated by the Spacelift stack dependency from foundation's iam_role_arn output"
  type        = string
  default     = ""
}
