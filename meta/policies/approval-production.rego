package spacelift

# Requires at least one approval and zero rejections before an apply can
# proceed. Confirmed against docs.spacelift.io/concepts/policy/approval-policy:
# reviews live under input.reviews.current, not input.session.

approve {
	count(input.reviews.current.approvals) > 0
	count(input.reviews.current.rejections) == 0
}

reject {
	count(input.reviews.current.rejections) > 0
}
