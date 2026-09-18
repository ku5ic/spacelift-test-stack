# Saved filters are the per-view saved searches in the top bar of a list
# screen. This provider version accepts four view types: stacks, blueprints,
# contexts and webhooks. is_public shares a filter with the whole account.
#
# `data` is a JSON blob whose inner `value` is itself a JSON string - the
# shape is copied from the provider's own example. The list under `order`
# controls which columns the view shows.

locals {
  saved_filter_sort = {
    direction = "ASC"
    option    = "starred"
  }
}

resource "spacelift_saved_filter" "failed_stacks" {
  name      = "test-stack: everything labelled test-stack"
  type      = "stacks"
  is_public = true

  data = jsonencode({
    key = "activeFilters"
    value = jsonencode({
      filters = [
        ["label", {
          key        = "label"
          filterName = "label"
          type       = "STRING"
          values     = ["test-stack"]
        }]
      ]
      sort = local.saved_filter_sort
      text = null
      order = [
        { name = "name", visible = true },
        { name = "state", visible = true },
        { name = "space", visible = true },
        { name = "vendor", visible = true },
        { name = "label", visible = true },
      ]
    })
  })
}

resource "spacelift_saved_filter" "aws_stacks" {
  name = "test-stack: AWS-backed stacks only"
  type = "stacks"
  # Machine users can only create public filters, and meta/ runs as one.
  is_public = true

  data = jsonencode({
    key = "activeFilters"
    value = jsonencode({
      filters = [
        ["label", {
          key        = "label"
          filterName = "label"
          type       = "STRING"
          values     = ["aws"]
        }]
      ]
      sort  = local.saved_filter_sort
      text  = null
      order = [{ name = "name", visible = true }, { name = "state", visible = true }]
    })
  })
}

resource "spacelift_saved_filter" "test_contexts" {
  name      = "test-stack: contexts"
  type      = "contexts"
  is_public = true

  data = jsonencode({
    key = "activeFilters"
    value = jsonencode({
      filters = [
        ["label", {
          key        = "label"
          filterName = "label"
          type       = "STRING"
          values     = ["test-stack"]
        }]
      ]
      sort  = { direction = "ASC", option = "name" }
      text  = null
      order = [{ name = "name", visible = true }, { name = "space", visible = true }, { name = "label", visible = true }]
    })
  })
}
