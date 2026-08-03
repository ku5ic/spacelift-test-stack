variable "bucket_name" {
  description = "Globally unique S3 bucket name"
  type        = string
}

variable "environment" {
  type    = string
  default = "test"
}

variable "versioning_enabled" {
  type    = bool
  default = true
}

variable "extra_tags" {
  type    = map(string)
  default = {}
}
