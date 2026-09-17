"""Writes one SSM parameter, mirroring what the Terraform stacks do."""

import os

import pulumi
import pulumi_aws as aws

name_prefix = os.environ.get("TF_VAR_name_prefix", "sk-spacelift-test")

marker = aws.ssm.Parameter(
    "pulumi-marker",
    name=f"/{name_prefix}/pulumi/hello",
    type="String",
    value="written by the pulumi stack",
    tags={"Environment": "test", "ManagedBy": "spacelift"},
)

pulumi.export("ssm_parameter_name", marker.name)
