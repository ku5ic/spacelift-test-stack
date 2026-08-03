package spacelift

# Older alternative to the native stack_dependency wiring in
# meta/dependencies.tf. `trigger` must be a set<string> of stack IDs/names
# (docs.spacelift.io/concepts/policy/trigger-policy), not a bare boolean -
# a bare `trigger { false }` rule conflicts with that shape at evaluation
# time ("conflicting rules ... found"). Left disabled (condition is always
# false) so it does not double-trigger the app stack alongside the
# dependency. Flip the hardcoded false to a real condition on
# input.run.state to compare trigger-policy behaviour against stack
# dependencies.

trigger["test-stack-app"] {
	false
}
