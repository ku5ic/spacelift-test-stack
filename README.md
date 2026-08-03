# Spacelift test stack

A hands-on playground for learning Spacelift the product, not just deploying AWS infrastructure through it.

If you're a developer who just joined Spacelift: this is the fastest way to see the platform's own concepts working end to end, on real infrastructure, without touching a customer account.

What it exercises:

- Stacks, contexts, policies, dependencies, integrations
- The "Spacelift managing Spacelift" pattern: a management stack (`meta/`) written against the `spacelift-io/spacelift` Terraform provider, creating three workload stacks (two Terraform, one Ansible)

Cost: stays inside AWS free tier (S3, IAM, SSM Parameter Store, CloudWatch Logs). No EC2, no VPC, no NAT gateways.

## Start here

Pick one path:

1. New to this repo, want to click through Spacelift's UI like a customer would -> **Option B** (manual, through the UI)
2. Comfortable running Terraform locally, want to see "Spacelift managing Spacelift" work -> **Option A**
3. Want the full self-managing pattern, applied by Spacelift itself -> **Option C**

Then check `Feature coverage` below to find which file covers which Spacelift concept.

## Layout

```
.spacelift/config.yml   Repo-root runtime config: before_init/before_apply hooks for test-stack-ansible-config
meta/                    Spacelift-managing-Spacelift: stacks, context, policies, dependencies, AWS integration
  policies/               Rego bodies for the six policy resources (LOGIN, PLAN x2, APPROVAL x2, NOTIFICATION, TRIGGER)
workloads/
  foundation/             Terraform: S3 bucket, IAM role, SSM parameter, CloudWatch log group
  app/                    Terraform: depends on foundation's outputs, writes into its bucket
  ansible-config/         Ansible: depends on foundation's outputs, writes into its bucket via amazon.aws
modules/
  s3-bucket/              Standalone module registered in the Module Registry
```

## Feature coverage

| Feature                                                          | Where                                                                                                           |
| ---------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| Stacks (Terraform x2, Ansible x1)                                | meta/stacks.tf                                                                                                  |
| Stack dependencies + output passing                              | meta/dependencies.tf                                                                                            |
| Contexts, environment variables, attachments                     | meta/contexts.tf                                                                                                |
| Policies: LOGIN, PLAN (x2), APPROVAL (x2), NOTIFICATION, TRIGGER | meta/policies.tf, meta/policies/\*.rego                                                                         |
| Cloud integration (AWS, STS AssumeRole)                          | meta/aws_integration.tf                                                                                         |
| Module Registry                                                  | meta/modules_registry.tf, modules/s3-bucket                                                                     |
| Lifecycle hooks (before_init, before_apply, after_apply)         | workloads/foundation, workloads/app: `.spacelift/config.yml`; ansible-config: repo-root `.spacelift/config.yml` |
| Webhooks / notifications                                         | meta/notifications.tf                                                                                           |
| Ansible vendor, native multi-IaC orchestration                   | workloads/ansible-config, meta/stacks.tf                                                                        |
| Drift detection                                                  | manual, see below                                                                                               |
| Blueprints                                                       | manual, see below                                                                                               |
| Private worker pools                                             | manual, see below                                                                                               |
| Spaces / RBAC                                                    | manual, see below                                                                                               |

## Things flagged for verification, not fabricated

A few provider details couldn't be scraped from the registry docs (they render client-side). Called out inline as comments, not asserted as fact:

- `ansible { playbook = "playbook.yml" }` on `spacelift_stack.ansible_config` (`meta/stacks.tf`)
  - UI confirms an Ansible vendor with a Playbook field; the resource block itself wasn't independently confirmed
  - If `terraform plan` rejects it: create that one stack manually in the UI, drop the block. Context, dependency, and policies still attach to it by `stack_id`.
- The `input.session` shape in `policies/login.rego`
  - `policies/approval-production.rego` was already confirmed to use `input.reviews.current` instead - see its header comment
- The exact rule name (`webhook` vs something else) in `policies/notification-failures-only.rego`

Before the first real apply: check these against `docs.spacelift.io` or `terraform providers schema -json`.

Everything else in `meta/` was confirmed against current registry docs while drafting this: stack, module, context, environment_variable, context_attachment, policy, policy_attachment, aws_integration, aws_integration_attachment, stack_dependency, stack_dependency_reference, webhook.

## Bootstrapping

All three options below produce the same end state: three stacks, one context, six policy resources, one AWS integration, one dependency wiring, one registered module. Pick whichever fits how you're exercising your instance.

### Option A: Terraform (`meta/`)

Use this to also exercise the "Spacelift managing Spacelift" pattern itself.

1. Create the AWS IAM role Spacelift will assume:
   - Trust policy: principal is Spacelift's AWS account, condition on the external ID Spacelift generates for this integration (`docs.spacelift.io/integrations/cloud-providers/aws`)
   - Permissions: S3, IAM (scoped to the `sk-spacelift-test-*` role/policy names), SSM Parameter Store, CloudWatch Logs
   - First pass: `PowerUserAccess` is fine, scope down later. Throwaway test account, not production.
2. Push this repo to your VCS and connect it to Spacelift under Source Control (skip if already connected).
3. `cd meta`
4. Set `vcs_repository`, `vcs_branch`, `aws_iam_role_arn` via `terraform.tfvars` or `-var`.
5. Export an administrative Spacelift API key: `SPACELIFT_API_KEY_ENDPOINT`, `SPACELIFT_API_KEY_ID`, `SPACELIFT_API_KEY_SECRET`.
6. `terraform init && terraform plan`
7. Apply. Creates the three stacks, the context, the policies, the dependency wiring, and the AWS integration attachments.
8. Trigger a run on `test-stack-foundation` first (no dependencies). Once it applies, its outputs unlock `test-stack-app` and `test-stack-ansible-config`.
9. Optional: once stable, promote to Option C below so future `meta/` changes apply through Spacelift, not locally.

### Option B: Manual, through the Spacelift UI

Use this to exercise stack creation, contexts, dependencies, and policies by hand, no local Terraform run. `meta/` isn't used in this path.

1. Source Control > connect the VCS integration this repo is pushed to.
2. Create the AWS IAM role (same as Option A step 1).
3. Create three stacks, all pointed at this repo's `main` branch, autodeploy off:

   | Stack name                | Project root             | Vendor                             | Labels                      |
   | ------------------------- | ------------------------ | ---------------------------------- | --------------------------- |
   | test-stack-foundation     | workloads/foundation     | Terraform 1.5.7                    | test-stack, foundation, aws |
   | test-stack-app            | workloads/app            | Terraform 1.5.7                    | test-stack, app, aws        |
   | test-stack-ansible-config | workloads/ansible-config | Ansible, Playbook = `playbook.yml` | test-stack, ansible         |

4. Cloud Integrations > AWS > add an integration using the role ARN from step 2 (generate credentials in worker = off, duration 1800s). Attach to all three stacks, read + write.
5. Create context `common-test-context` with two plain-text environment variables, attached to all three stacks at priority 0:
   - `TF_VAR_aws_region=eu-west-1`
   - `TF_VAR_name_prefix=sk-spacelift-test`
6. Stack Settings > Dependencies:
   - `test-stack-app` depends on `test-stack-foundation`: map output `bucket_name` -> input `TF_VAR_foundation_bucket_name`, output `iam_role_arn` -> input `TF_VAR_foundation_role_arn`
   - `test-stack-ansible-config` depends on `test-stack-foundation`: map output `bucket_name` -> input `FOUNDATION_BUCKET_NAME`
7. Policies > Create policy, pasting each body from `meta/policies/*.rego`:

   | Policy                        | Type         | Attach to                                                                                                          |
   | ----------------------------- | ------------ | ------------------------------------------------------------------------------------------------------------------ |
   | restrict-login-to-test-team   | LOGIN        | account-wide, no attachment (changes login behavior for the whole instance, not just these stacks)                 |
   | require-environment-tag       | PLAN         | foundation, app                                                                                                    |
   | protect-bucket-from-destroy   | PLAN         | foundation                                                                                                         |
   | require-approval-before-apply | APPROVAL     | app                                                                                                                |
   | restrict-task-commands        | APPROVAL     | foundation (migrated off the deprecated TASK policy type; blocks `destroy`/`state rm` runs)                        |
   | notify-on-failed-runs-only    | NOTIFICATION | foundation, app (attached via `autoattach:aws` label, not a policy_attachment - both stacks carry the `aws` label) |
   | trigger-app-after-foundation  | TRIGGER      | foundation (kept disabled in the rego body, a deliberately-off alternative to step 6's native dependency)          |

8. Module Registry > Add module, same repo, project root `modules/s3-bucket`, Terraform provider `aws`.
9. Trigger a run on `test-stack-foundation` first. Once it applies, trigger `test-stack-app` and `test-stack-ansible-config`.

Bonus: this path sidesteps the one unverified thing in this repo (the `ansible {}` provider block) - you pick the Ansible vendor and type the playbook path directly in the UI.

### Option C: Single administrative stack, orchestrated

Same end state as Option A, but `meta/`'s apply runs inside Spacelift instead of on your machine. This is "Spacelift managing Spacelift" running for real.

1. Cloud Integrations > AWS > Create integration. Name it - the screen shows a ready-made trust-policy JSON with your instance's real AWS principal account ID and ExternalId already filled in.
2. Copy that JSON, then cancel out without saving. (`meta/`'s own apply creates this integration under the same name - a manually saved one first will conflict with it.)
3. AWS Console > IAM > Roles > Create role > Custom trust policy > paste the copied JSON.
4. Attach a permissions policy (`AdministratorAccess`/`PowerUserAccess` is fine for a throwaway test account), name it, create it.
5. Copy the resulting Role ARN.
6. Source Control > connect the VCS integration (same as Option B step 1).
7. Create one stack: project root `meta`, Terraform vendor, **Administrative = true**.
   - Marking a stack administrative auto-injects `SPACELIFT_API_TOKEN` into its runs, so `provider "spacelift" {}` (`meta/providers.tf`, already zero-config) authenticates with no API key setup.
8. That stack's **Environment** tab > **Add variable**:
   - `TF_VAR_vcs_repository=<owner>/<repo>`
   - `TF_VAR_aws_iam_role_arn=<role ARN from step 5>`
   - `TF_VAR_vcs_branch` only needed if you're not on `main` (already defaults to that)
9. Trigger a run, review the plan, confirm apply. One run creates the three workload stacks, the context, the six policies, the AWS integration, and the module registry entry.
10. Trigger `test-stack-foundation` first, then `test-stack-app` / `test-stack-ansible-config` (same ordering as the other options - the meta stack doesn't auto-fire these).

## Manual/UI-only pieces worth exploring separately

These need live infra context this scaffold can't fabricate, or don't have a stable provider resource to script safely:

- **Drift detection**: enable a scheduled proposed run on `test-stack-foundation` (Stack settings > Scheduling). Manually change a tag in the AWS console, watch it get flagged.
- **Blueprints**: Blueprints > Create Blueprint, point it at `workloads/foundation` with an input parameter (e.g. `name_prefix`), publish, self-service a new stack from it.
- **Private worker pools**: needs a real worker (Docker container or ECS/Fargate task) running the Spacelift launcher and polling your account. Do this once the above is solid - it's the clearest way to see how `worker_pool_id` changes behavior versus shared public workers.
- **Spaces and RBAC**: create a `test` space, move the three stacks into it, test how login policy and space-level access control interact.

## Teardown

Destroy `app` and `ansible-config` first (their state references `foundation`'s bucket), then `foundation`.

- **Option A** (`meta/`): `terraform destroy` inside `meta/`.
- **Option B** (manual): delete the three stacks, the context, the six policies, the AWS integration, and the registered module through the UI, in that order.
- **Option C** (administrative stack): trigger a destroy run on the meta stack itself.
