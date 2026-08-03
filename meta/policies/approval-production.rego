package spacelift

# Requires at least one approval and zero rejections before an apply can
# proceed. The exact shape of input.session.approved/rejected is documented
# at docs.spacelift.io/concepts/policy/approval-policy, verify before relying
# on this in a real account.

approve {
	count(input.session.approved) > 0
	count(input.session.rejected) == 0
}

reject {
	count(input.session.rejected) > 0
}
