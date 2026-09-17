package spacelift

# GIT_PUSH policy: only start a run when the push actually touched this
# stack's project root, so editing the README doesn't trigger every stack in
# the repo. Rule names and the input.push shape are confirmed against
# docs.spacelift.io/concepts/policy/push-policy.
#
# track   -> tracked run on the stack's own branch (can be applied)
# propose -> proposed run on any other branch (plan only, for PRs)
# ignore  -> no run at all

track {
	affected
	input.push.branch == input.stack.branch
}

propose {
	affected
	input.push.branch != input.stack.branch
}

ignore {
	not affected
}

affected {
	path := input.push.affected_files[_]
	startswith(normalize(path), normalize(input.stack.project_root))
}

normalize(path) = trim(path, "/")
