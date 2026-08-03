package spacelift

# Older alternative to the native stack_dependency wiring in
# meta/dependencies.tf. Left disabled (trigger is always false) so it does
# not double-trigger the app stack alongside the dependency. Flip the
# hardcoded false to a real condition on input.run_updated to compare
# trigger-policy behaviour against stack dependencies.

trigger {
	false
}
