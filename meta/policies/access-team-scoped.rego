package spacelift

# ACCESS policy: decides who can see and operate a single stack, on top of
# whatever space-level role the user already holds. Rule names confirmed
# against docs.spacelift.io/concepts/policy/stack-access-policy - write
# implies read, deny overrides both, deny_write revokes write only.
#
# Deliberately permissive: this playground has no real teams, and a policy
# that locked everyone out would be indistinguishable from a broken one.

read {
	input.session.login != ""
}

write {
	input.session.admin
}

write {
	input.session.teams[_] == "spacelift-test-team"
}
