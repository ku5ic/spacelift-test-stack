terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

variable "name_prefix" {
  type    = string
  default = "sk-spacelift-test"
}

resource "aws_ssm_parameter" "terragrunt_marker" {
  name  = "/${var.name_prefix}/terragrunt/hello"
  type  = "String"
  value = "written by the terragrunt stack"

  tags = {
    Environment = "test"
    ManagedBy   = "spacelift"
  }
}

output "ssm_parameter_name" {
  value = aws_ssm_parameter.terragrunt_marker.name
}
