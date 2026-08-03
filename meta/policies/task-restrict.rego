package spacelift

# Blocks destructive one-off Tasks (ad-hoc commands run outside the normal
# plan/apply flow), e.g. `terraform destroy` or `terraform state rm`.

deny[msg] {
	some i
	contains(input.command[i], "destroy")
	msg := "destructive commands are not allowed as ad-hoc Tasks on this stack"
}

deny[msg] {
	some i
	contains(input.command[i], "state rm")
	msg := "state manipulation is not allowed as an ad-hoc Task on this stack"
}
