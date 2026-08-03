package spacelift

# Fires a webhook notification only on failed tracked runs. Mirrors
# Spacelift's own documented Slack notification-policy example but targets
# the generic webhook rule; verify the rule name for your account against
# docs.spacelift.io/concepts/policy/notification-policy before relying on
# this, notification policies vary the rule name by channel type.

webhook[{"endpoint": "default"}] {
	input.run_updated != null
	input.run_updated.run.state == "FAILED"
}
