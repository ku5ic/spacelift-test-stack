package spacelift

# Blocks any plan that would destroy the foundation S3 bucket. Useful for
# proving policy-as-code actually stops a destructive apply in this test
# setup; remove or scope it down once you are done exercising it.

deny[msg] {
	resource := input.terraform.resource_changes[_]
	resource.type == "aws_s3_bucket"
	resource.change.actions[_] == "delete"
	msg := sprintf("destroying %s is blocked by policy", [resource.address])
}
