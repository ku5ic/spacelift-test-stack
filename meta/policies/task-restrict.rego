package spacelift

# Blocks destructive one-off Tasks (ad-hoc commands run outside the normal
# plan/apply flow), e.g. `terraform destroy` or `terraform state rm`.
# Migrated from a TASK policy (deprecated) to APPROVAL, following
# docs.spacelift.io/concepts/policy/task-run-policy's own migration example:
# reject on the restricted condition, approve everything else.

reject {
	contains(input.run.command, "destroy")
}

reject {
	contains(input.run.command, "state rm")
}

approve { not reject }
