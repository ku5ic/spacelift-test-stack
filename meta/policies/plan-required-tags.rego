package spacelift

# Denies any apply where a taggable resource is missing the "Environment"
# tag. Adjust resource_types_requiring_tags to match what actually ships in
# workloads/foundation and workloads/app.

resource_types_requiring_tags := {
	"aws_s3_bucket",
	"aws_iam_role",
	"aws_ssm_parameter",
	"aws_cloudwatch_log_group",
}

deny[msg] {
	resource := input.terraform.resource_changes[_]
	resource_types_requiring_tags[resource.type]
	resource.change.actions[_] != "delete"
	not resource.change.after.tags.Environment
	msg := sprintf("%s.%s is missing the required 'Environment' tag", [resource.type, resource.name])
}
