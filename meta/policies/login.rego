package spacelift

# Login policy: deny by default, allow members of the named team or admins.
# The exact shape of input.session (teams, admin, login, etc) is documented
# at docs.spacelift.io/concepts/policy/login-policy, verify field names
# there before relying on this in a real account.

default allow = false

allow {
	input.session.teams[_] == "spacelift-test-team"
}

allow {
	input.session.admin
}
