# Spacelift test stack

A dev-environment playground that turns on as much of Spacelift the product as one repo can, so you can click through every feature against real infrastructure without touching a customer account.

Built for frontend work on Spacelift itself: the point is that every list screen has rows, every detail screen has a non-default value, and every empty state you hit is one you deliberately left empty.

Cost: stays inside AWS free tier (S3, IAM, SSM Parameter Store, CloudWatch Logs). No EC2, no VPC, no NAT gateways.

## Quick start

1. Create an AWS IAM role Spacelift can assume (Cloud Integrations > AWS > Create integration shows you the exact trust policy JSON, including your account's principal and external ID). `PowerUserAccess` is fine on a throwaway account.

   That JSON allows `sts:AssumeRole` only, which is all this repo needs as shipped. To turn `tag_assume_role` back on in `meta/aws_integration.tf`, add a second statement allowing `sts:TagSession` to the same principal under the same `sts:ExternalId` condition - AWS fails the whole AssumeRole call, not just the tagging, when session tags are passed to a role whose trust policy omits it.

2. Push this repo to your VCS and connect it under Source Control.
3. Create one stack in the UI: project root `meta`, **OpenTofu** vendor (`meta/versions.tf` needs >= 1.6.0, and Spacelift's Terraform FOSS workflow stops at 1.5.7). Then open its Settings > Roles and assign **Space admin** on space `root`. That is what injects `SPACELIFT_API_TOKEN`, so `provider "spacelift" {}` needs no API key.

   The old **Administrative = true** toggle is gone from Stack settings > Behavior; the provider deprecates the field too. Roles are the replacement.

4. On that stack's Environment tab, add `TF_VAR_vcs_repository=<repo-name>` and `TF_VAR_aws_iam_role_arn=<role ARN>`.

   `vcs_repository` is the repository **name only**, no owner - the provider says so outright, and the owner comes from the VCS integration. If your repo sits outside the default integration's namespace, add a `github_enterprise { namespace = "..." }` (or the block matching your provider) to each stack in `meta/stacks.tf`.

5. Trigger a run, confirm the apply.
6. Trigger `test-stack-foundation`. Its outputs unblock `test-stack-app`, `test-stack-ansible-config` and `test-stack-tofu`.

Variables reach the stack as `TF_VAR_*` on its Environment tab, not through a tfvars file - `terraform.tfvars` is for the local path only. Every flag in the table below works the same way: `TF_VAR_enable_extra_vendor_stacks=true`, and so on.

Optional step 7, once that's stable: adopt the administrative stack into this configuration so it manages itself. `meta/self_management.tf` has the import-first flow, and it matters - flipping `manage_meta_stack` on without importing first makes the apply try to create a duplicate stack.

Prefer running `meta/` from your laptop? `cp meta/example.tfvars meta/terraform.tfvars`, fill it in, export `SPACELIFT_API_KEY_ENDPOINT` / `_ID` / `_SECRET` from an administrative API key, then `terraform init && terraform apply` inside `meta/`.

One apply creates: 4 spaces, 5 stacks, 2 contexts, 8 policies, 3 roles, 2 blueprints, 1 worker pool, 1 VCS agent pool, 1 module, 1 private provider, 3 saved filters, 2 drift schedules, 1 scheduled run, 1 scheduled task, the AWS integration and the dependency graph.

## Layout

```
meta/                      Spacelift managing Spacelift. One .tf file per feature area.
  policies/                  Rego bodies, one per policy
  blueprints/                Blueprint YAML, rendered through templatefile()
  example.tfvars             Copy to terraform.tfvars
workloads/
  foundation/                Terraform: S3 bucket, IAM role, SSM parameter, log group
  app/                       Terraform: consumes foundation's outputs
  ansible-config/            Ansible: consumes foundation's outputs
  tofu-demo/                 Same shape as app, run through OpenTofu
  terragrunt-demo/           Terragrunt driving OpenTofu, Spacelift-managed state
  pulumi-demo/               Behind enable_extra_vendor_stacks
  cloudformation-demo/       Behind enable_extra_vendor_stacks
  kubernetes-demo/           Behind enable_extra_vendor_stacks
modules/s3-bucket/         Published to the private Module Registry
.spacelift/config.yml      Repo-root runtime config, scoped to the Ansible stack
```

## What's on by default

| UI area            | What you'll find                                                                                                              | Source                                          |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------- |
| Spaces             | `test-stack` with `development` / `staging` / `production` children, all inheriting entities                                  | `meta/spaces.tf`                                |
| Stacks             | 5 stacks across 3 vendors (Terraform, OpenTofu, Terragrunt, Ansible), each with different settings toggled                    | `meta/stacks.tf`, `meta/stacks_multi_iac.tf`    |
| Stack dependencies | Two levels deep: foundation -> app / ansible / tofu, tofu -> terragrunt, with output-to-input mapping                         | `meta/dependencies.tf`                          |
| Contexts           | One explicit-attachment context (env vars, a write-only var, a mounted file), one autoattach context carrying lifecycle hooks | `meta/contexts.tf`                              |
| Policies           | APPROVAL x2, GIT_PUSH, LOGIN, NOTIFICATION, PLAN x2, TRIGGER. ACCESS is gone: Spacelift disabled it on 2026-05-30             | `meta/policies.tf`, `meta/policies/*.rego`      |
| Notifications      | Inbox notifications on every finished and failed run, no external endpoint needed                                             | `meta/policies/notification-failures-only.rego` |
| Cloud integrations | AWS via STS AssumeRole, attached to 5 stacks and the module                                                                   | `meta/aws_integration.tf`                       |
| Module registry    | `s3-bucket` module with its own worker pool, workflow tool and preview settings                                               | `meta/registry.tf`                              |
| Provider registry  | One private provider entry, versions pushed separately with `spacectl`                                                        | `meta/registry.tf`                              |
| Blueprints         | One PUBLISHED (self-service form with text, select and boolean inputs), one DRAFT                                             | `meta/blueprints.tf`                            |
| Worker pools       | One private pool plus one VCS agent pool, both created empty                                                                  | `meta/worker_pools.tf`                          |
| Scheduling         | Daily drift detection on foundation, half-hourly reconciling drift on tofu, a nightly scheduled run, a weekly scheduled task  | `meta/scheduling.tf`                            |
| Roles / RBAC       | viewer / operator / admin roles built from the `spacelift_role_actions` data source, with the viewer role bound to a stack    | `meta/rbac.tf`                                  |
| Saved filters      | Three saved views, all public - a machine user cannot create a private one                                                    | `meta/saved_filters.tf`                         |

## What's behind a flag

Everything here costs money, needs infrastructure this repo can't create, or changes account-wide behaviour. All default to off; set them in `terraform.tfvars`.

| Variable                                 | Turns on                                                                                             | Needs first                                                                          |
| ---------------------------------------- | ---------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| `notification_webhook_url`               | Per-stack webhooks, the named webhook, its secret header, and the notification policy's webhook rule | An endpoint. https://webhook.site gives you one in a click.                          |
| `audit_trail_webhook_url`                | Audit trail webhook with custom headers                                                              | Same.                                                                                |
| `attach_worker_pool`                     | Points all 5 stacks at the private worker pool                                                       | A running launcher, or every run queues forever. See below.                          |
| `enable_extra_vendor_stacks`             | Pulumi, CloudFormation and Kubernetes stacks                                                         | A Pulumi backend, a CFN template bucket, a cluster. They populate the UI either way. |
| `trigger_initial_runs`                   | A tracked run, a proposed run and a task, straight from the apply                                    | Nothing, but it starts touching AWS during `terraform apply`.                        |
| `scheduled_delete_at`                    | Stack TTL on the OpenTofu stack                                                                      | A unix timestamp.                                                                    |
| `enable_stack_destructors`               | Makes `terraform destroy` on `meta/` tear down the AWS resources too                                 | Read the Teardown section first.                                                     |
| `enable_gcp_service_account`             | Spacelift-minted GCP service account on foundation                                                   | A GCP project to grant it something in.                                              |
| `azure_tenant_id`                        | Azure integration with autoattach                                                                    | An Azure AD tenant, plus admin consent afterwards.                                   |
| `security_email`, `default_runner_image` | Account-wide settings                                                                                | Nothing, but they affect stacks outside this playground.                             |
| `idp_group_name`                         | IdP group mapping, plus the admin and operator role bindings that hang off it                        | SSO configured on the account.                                                       |
| `invited_user_email`                     | User invite with a space-scoped policy                                                               | An invite flow on the account.                                                       |
| `module_version_number`                  | Publishes a module version without a git tag                                                         | A semver.                                                                            |
| `manage_meta_stack`                      | Adopts the administrative stack running `meta/` into this configuration                              | A `terraform import` first. See `meta/self_management.tf`.                           |

### Starting a private worker

```sh
cd meta
terraform output -raw worker_pool_config       # SPACELIFT_TOKEN
terraform output -raw worker_pool_private_key  # SPACELIFT_POOL_PRIVATE_KEY
docker run -e SPACELIFT_TOKEN=... -e SPACELIFT_POOL_PRIVATE_KEY=... public.ecr.aws/spacelift/launcher
```

Then set `attach_worker_pool = true` and re-apply.

## This repo is public

Nothing here holds a credential, and `gitleaks` is clean on both the history and the working tree. Keeping it that way:

- `terraform.tfvars` is gitignored; `meta/example.tfvars` is the only tfvars file meant to be committed, and it holds placeholders. Your repo name, role ARN and webhook URLs go in the ignored one.
- `webhook_secret` has no default. A default in a public repo is a published secret, so empty means deliveries go unsigned rather than signed with a secret everyone can read.
- `DEMO_MASKED_VALUE` in `meta/contexts.tf` is a literal placeholder. `write_only` controls what Spacelift shows you after saving; it does nothing about a value sitting in a public file.
- No API keys are created. An API key is the one role subject that works without SSO, but its secret lands in Terraform state, so roles bind through the IdP group path instead. The trade-off: the operator and admin roles stay unbound until you set `idp_group_name`.
- The worker pool private key and join token are Terraform _state_, not repo content. State is gitignored locally and lives inside Spacelift when `meta/` runs as an administrative stack. Don't paste `terraform output` results anywhere public.
- Point this at a throwaway AWS account. `PowerUserAccess` on the assumed role is suggested for convenience, and the bucket names are globally unique only because of a random suffix.

## Still worth verifying against your account

Written from the provider schema (v1.55.0) and the public docs, but not exercised against a live account while drafting:

- `input.session` shape in `policies/login.rego`. `docs.spacelift.io/concepts/policy/login-policy` is the reference.
- The `endpoint_id` the notification policy matches on. It is the named webhook's slug, visible under Webhooks in the UI, not necessarily the display name.
- The blueprint's `attachments`, `environment` and `hooks` sub-keys. Deliberately left out of `meta/blueprints/workload-stack.yaml.tftpl` - a bad key in a PUBLISHED blueprint fails the whole apply. Build them in the UI's blueprint editor, which validates live, then paste the working YAML back.
- Terragrunt and OpenTofu tool versions pinned in `meta/stacks_multi_iac.tf`. Check what your account's runner images actually ship.

Everything else was confirmed against the provider schema, including the `ansible { playbook = ... }` block that earlier versions of this README flagged as unverified.

## Not scripted, worth doing by hand

- **Stack locking**, **run promotion** and **local previews** all need a live run to demonstrate. `allow_run_promotion` and `enable_local_preview` are already on for `test-stack-app`.
- **Resources view**: apply foundation, then change a tag in the AWS console and wait for the 07:00 drift run.
- **INTENT policies** and the **Templates** feature (`spacelift_template` / `_version` / `_deployment`) are newer than the rest of this repo and aren't wired up here.
- **Plugins** (`spacelift_plugin_template`, `spacelift_plugin`) likewise.
- **Migrating off `administrative`**: the provider deprecates the flag in favour of attaching a role with space-admin actions to the stack. `meta/self_management.tf` keeps the flag and says why - turning it off during an apply revokes the token that apply is running on. Do that migration from a second stack or from your laptop.
- **Spacelift-hosted repos** (`spacelift_repo`, `spacelift_repo_file`) - a self-contained alternative to an external VCS.

## Teardown

`app`, `ansible-config` and `tofu` write into `foundation`'s bucket, so they go first.

- **Default**: destroy the three dependent stacks through the UI, then foundation, then `terraform destroy` in `meta/`.
- **With `enable_stack_destructors = true`**: `terraform destroy` in `meta/` does the whole thing, in dependency order. `foundation` also has `protect_from_deletion = true`, so clear that first.
