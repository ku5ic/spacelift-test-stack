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
