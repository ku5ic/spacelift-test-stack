package spacelift

# Rule names and object keys confirmed against
# docs.spacelift.io/concepts/policy/notification-policy: a notification
# policy can define inbox, slack, webhook and pull_request; the webhook rule
# takes endpoint_id, which is the id of a named webhook as it appears in
# input.webhook_endpoints.
#
# The inbox rules need no external endpoint at all, so they populate the
# in-app Notifications view on any account. The webhook rule only fires once
# a named webhook exists - see meta/webhooks.tf.

inbox[{"title": title, "body": body}] {
	input.run_updated.run.state == "FAILED"
	title := sprintf("%s: run failed", [input.run_updated.stack.name])
	body := sprintf("Run %s ended in FAILED", [input.run_updated.run.id])
}

inbox[{"title": title}] {
	input.run_updated.run.state == "FINISHED"
	input.run_updated.run.type == "TRACKED"
	title := sprintf("%s: apply finished", [input.run_updated.stack.name])
}

# If this never fires, check the endpoint's real id under Webhooks in the
# UI - it is the named webhook's slug, not its display name.
webhook[{"endpoint_id": endpoint.id}] {
	endpoint := input.webhook_endpoints[_]
	endpoint.id == "test-stack-notifications"
	input.run_updated.run.state == "FAILED"
}
