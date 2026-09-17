# Roles and role attachments: Spacelift's newer RBAC model, where a role is
# a named bundle of actions and an attachment binds that role to a subject
# (user, API key, IdP group or stack) within one space.
#
# Actions are read from the spacelift_role_actions data source rather than
# hardcoded, so this stays correct as the action list grows. Filter, don't
# type them out.

data "spacelift_role_actions" "all" {}

locals {
  viewer_actions = [for action in data.spacelift_role_actions.all.actions : action if can(regex("_READ$", action))]

  operator_actions = distinct(concat(
    local.viewer_actions,
    [for action in data.spacelift_role_actions.all.actions : action if can(regex("^RUN_", action))],
  ))

  admin_actions = [for action in data.spacelift_role_actions.all.actions : action if can(regex("^SPACE_ADMIN$", action))]
}

resource "spacelift_role" "viewer" {
  name        = "test-stack-viewer"
  description = "Read-only across the test-stack spaces"
  actions     = local.viewer_actions
}

resource "spacelift_role" "operator" {
  name        = "test-stack-operator"
  description = "Read everything plus trigger and confirm runs"
  actions     = local.operator_actions
}

resource "spacelift_role" "admin" {
  name        = "test-stack-admin"
  description = "Full control of the test-stack space subtree"
  actions     = local.admin_actions
}

# Binding a role to a stack rather than a person is how a stack's own
# administrative runs get scoped permissions instead of full admin.
resource "spacelift_role_attachment" "foundation_viewer" {
  role_id  = spacelift_role.viewer.id
  space_id = spacelift_space.development.id
  stack_id = spacelift_stack.foundation.slug
}

# Roles need a subject to bind to. An API key would be the one subject that
# works without SSO, but its secret lands in Terraform state, so this repo
# binds through the IdP group path instead - nothing sensitive is created.
#
# That means the two people-facing roles stay unbound until SSO is
# configured and var.idp_group_name is set. The stack-bound attachment above
# is the one that works out of the box.
resource "spacelift_idp_group_mapping" "test_team" {
  count = var.idp_group_name != "" ? 1 : 0

  name        = var.idp_group_name
  description = "Maps an SSO group onto the test-stack spaces"

  policy {
    role     = "ADMIN"
    space_id = spacelift_space.development.id
  }

  policy {
    role     = "READ"
    space_id = spacelift_space.production.id
  }
}

resource "spacelift_role_attachment" "test_team_admin" {
  count = var.idp_group_name != "" ? 1 : 0

  role_id              = spacelift_role.admin.id
  space_id             = spacelift_space.test_stack.id
  idp_group_mapping_id = spacelift_idp_group_mapping.test_team[0].id
}

# Same group, narrower role, narrower space - which is the whole point of
# binding a role per space rather than per person.
resource "spacelift_role_attachment" "test_team_operator" {
  count = var.idp_group_name != "" ? 1 : 0

  role_id              = spacelift_role.operator.id
  space_id             = spacelift_space.development.id
  idp_group_mapping_id = spacelift_idp_group_mapping.test_team[0].id
}

resource "spacelift_user" "invited" {
  count = var.invited_user_email != "" ? 1 : 0

  username         = var.invited_username
  invitation_email = var.invited_user_email

  policy {
    role     = "WRITE"
    space_id = spacelift_space.development.id
  }
}
