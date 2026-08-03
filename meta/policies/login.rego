package spacelift

# Login policy: allow members of the named team or admins. No `default allow`
# here on purpose - Spacelift merges all active LOGIN policies into one
# evaluation, and two policies each declaring a default for the same rule
# conflicts ("multiple default rules ... found"). The exact shape of
# input.session (teams, admin, login, etc) is documented at
# docs.spacelift.io/concepts/policy/login-policy, verify field names there
# before relying on this in a real account.

allow {
	input.session.teams[_] == "spacelift-test-team"
}

allow {
	input.session.admin
}
