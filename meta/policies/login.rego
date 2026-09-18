package spacelift

# Login policy: allow anyone already a member of the account, plus the named
# team. No `default allow` here on purpose - Spacelift merges all active LOGIN
# policies into one evaluation, and two policies each declaring a default for
# the same rule conflicts ("multiple default rules ... found").
#
# Do NOT reference input.session.admin. It is not part of the login policy
# input (docs.spacelift.io/concepts/policy/login-policy lists creator_ip,
# idp_subject, login, machine, name, teams, member), so the rule silently
# never matches. An earlier version of this file gated on it, which left
# `member` unchecked and no matching rule for ordinary members at all.
#
# input.session.member is the field that actually distinguishes an existing
# account member from a stranger.

allow {
	input.session.member
}

allow {
	input.session.teams[_] == "spacelift-test-team"
}
