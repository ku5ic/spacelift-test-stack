# Spacelift test stack

A repo for exercising Spacelift's own capabilities, not just deploying AWS infrastructure through it. It uses the "Spacelift managing Spacelift" pattern: a management stack (meta/) written against the spacelift-io/spacelift Terraform provider that creates the actual test stacks, contexts, policies, dependencies, and integrations, plus two Terraform workloads and one native Ansible workload for those stacks to run.

Costs stay inside AWS free tier: S3, IAM, SSM Parameter Store (standard tier), CloudWatch Logs (small retention). No EC2, no VPC, no NAT gateways.

## Layout

```
meta/                    Spacelift-managing-Spacelift: stacks, context, policies, dependencies, AWS integration
  policies/               Rego bodies for the six policy types
workloads/
  foundation/             Terraform: S3 bucket, IAM role, SSM parameter, CloudWatch log group
  app/                    Terraform: depends on foundation's outputs, writes into its bucket
  ansible-config/         Ansible: depends on foundation's outputs, writes into its bucket via amazon.aws
modules/
  s3-bucket/              Standalone module registered in the Module Registry
```

## Feature coverage

| Feature                                                           | Where                                       |
| ----------------------------------------------------------------- | ------------------------------------------- |
| Stacks (Terraform x2, Ansible x1)                                 | meta/stacks.tf                              |
| Stack dependencies + output passing                               | meta/dependencies.tf                        |
| Contexts, environment variables, attachments                      | meta/contexts.tf                            |
| Policies: LOGIN, PLAN (x2), APPROVAL, TASK, NOTIFICATION, TRIGGER | meta/policies.tf, meta/policies/\*.rego     |
| Cloud integration (AWS, STS AssumeRole)                           | meta/aws_integration.tf                     |
| Module Registry                                                   | meta/modules_registry.tf, modules/s3-bucket |
| Lifecycle hooks (before_init, after_apply)                        | workloads/\*/.spacelift/config.yml          |
| Webhooks / notifications                                          | meta/notifications.tf                       |
| Ansible vendor, native multi-IaC orchestration                    | workloads/ansible-config, meta/stacks.tf    |
| Drift detection                                                   | manual, see below                           |
| Blueprints                                                        | manual, see below                           |
| Private worker pools                                              | manual, see below                           |
| Spaces / RBAC                                                     | manual, see below                           |

## Things flagged for verification, not fabricated

A few provider details could not be scraped from the registry docs (they render client-side) and are called out inline as comments rather than asserted as fact:

- `ansible { playbook = "playbook.yml" }` on `spacelift_stack.ansible_config` (meta/stacks.tf). The UI confirms an Ansible vendor with a Playbook field; the exact block name/args on the resource were not independently confirmed. If `terraform plan` rejects it, create that one stack manually in the UI and drop the block, everything else in this repo (context, dependency, policies) still attaches to it by `stack_id`.
- The `input.session` shape used in `policies/login.rego` and `policies/approval-production.rego`.
- The exact rule name (`webhook` vs something else) in `policies/notification-failures-only.rego`.

Check these against `docs.spacelift.io` or `terraform providers schema -json` before the first real apply. Everything else in meta/ (stack, module, context, environment_variable, context_attachment, policy, policy_attachment, aws_integration, aws_integration_attachment, stack_dependency, stack_dependency_reference, webhook) was confirmed against current registry documentation and blog examples while drafting this.

## Bootstrapping

All three paths below produce the same end state: three stacks, one context, six policies, one AWS integration, one dependency wiring, one registered module. Pick whichever fits how you're exercising your instance.

### Option A: Terraform (`meta/`)

Use this to also exercise the "Spacelift managing Spacelift" pattern itself.

1. Create the AWS IAM role Spacelift will assume:
   - Trust policy: principal is Spacelift's AWS account, condition on the external ID Spacelift generates for this integration (see `docs.spacelift.io/integrations/cloud-providers/aws`, `spacelift_aws_integration_attachment_external_id` data source if you want to fully automate this later).
   - Permissions: S3, IAM (scoped to the `sk-spacelift-test-*` role/policy names), SSM Parameter Store, CloudWatch Logs.
   - For a first pass you can attach `PowerUserAccess` scoped down later; this is a throwaway test account pattern, not a production one.
2. Push this repo to GitHub (or your VCS of choice) and connect it to Spacelift under Source Control if not already connected.
3. `cd meta`, set `vcs_repository`, `vcs_branch`, `aws_iam_role_arn` (either via `terraform.tfvars` or `-var`), export an administrative Spacelift API key (`SPACELIFT_API_KEY_ENDPOINT`, `SPACELIFT_API_KEY_ID`, `SPACELIFT_API_KEY_SECRET`), then `terraform init && terraform plan`.
4. Apply. This creates the three stacks, the context, the policies, the dependency wiring, and the AWS integration attachments.
5. Trigger a run on `test-stack-foundation` first (it has no dependencies). Once it completes with an apply phase, its outputs become available and `test-stack-app` / `test-stack-ansible-config` can be triggered.
6. Optional: once this is stable, promote it to the self-managing setup in Option C below, so future changes to `meta/` are applied through Spacelift rather than locally.

### Option B: Manual, through the Spacelift UI

Use this to exercise stack creation, contexts, dependencies, and policies as a user would click through them, with no local Terraform run at all. `meta/` is not used in this path.

1. Source Control > connect the VCS integration this repo is pushed to.
2. Create the AWS IAM role (same as Option A step 1).
3. Create three stacks, all pointed at this repo's `main` branch, autodeploy off:

   | Stack name                | Project root             | Vendor                             | Labels                      |
   | ------------------------- | ------------------------ | ---------------------------------- | --------------------------- |
   | test-stack-foundation     | workloads/foundation     | Terraform 1.9.8                    | test-stack, foundation, aws |
   | test-stack-app            | workloads/app            | Terraform 1.9.8                    | test-stack, app, aws        |
   | test-stack-ansible-config | workloads/ansible-config | Ansible, Playbook = `playbook.yml` | test-stack, ansible         |

4. Cloud Integrations > AWS > add an integration using the role ARN from step 2 (generate credentials in worker = off, duration 1800s). Attach to all three stacks, read + write.
5. Create context `common-test-context` with two plain-text environment variables: `TF_VAR_aws_region=eu-west-1`, `TF_VAR_name_prefix=sk-spacelift-test`. Attach to all three stacks, priority 0.
6. Stack Settings > Dependencies:
   - `test-stack-app` depends on `test-stack-foundation`: map output `bucket_name` -> input `TF_VAR_foundation_bucket_name`, output `iam_role_arn` -> input `TF_VAR_foundation_role_arn`.
   - `test-stack-ansible-config` depends on `test-stack-foundation`: map output `bucket_name` -> input `FOUNDATION_BUCKET_NAME`.
7. Policies > Create policy, pasting each body from `meta/policies/*.rego`:

   | Policy                        | Type         | Attach to                                                                                                      |
   | ----------------------------- | ------------ | -------------------------------------------------------------------------------------------------------------- |
   | restrict-login-to-test-team   | LOGIN        | account-wide, no attachment (this changes login behavior for the whole instance, not just these stacks)        |
   | require-environment-tag       | PLAN         | foundation, app                                                                                                |
   | protect-bucket-from-destroy   | PLAN         | foundation                                                                                                     |
   | require-approval-before-apply | APPROVAL     | app                                                                                                            |
   | restrict-task-commands        | TASK         | foundation                                                                                                     |
   | notify-on-failed-runs-only    | NOTIFICATION | foundation, app                                                                                                |
   | trigger-app-after-foundation  | TRIGGER      | foundation (kept disabled in the rego body, it's a deliberately-off alternative to step 6's native dependency) |

8. Module Registry > Add module, same repo, project root `modules/s3-bucket`, Terraform provider `aws`.
9. Trigger a run on `test-stack-foundation` first. Once it applies, trigger `test-stack-app` and `test-stack-ansible-config`.

Doing this through the UI also sidesteps the one thing in this repo that couldn't be verified against a live schema (see "Things flagged for verification" above): you pick the Ansible vendor and type the playbook path directly, instead of trusting the `ansible {}` provider block.

### Option C: Single administrative stack, orchestrated

Same end state as Option A, but `meta/`'s apply happens inside a Spacelift run instead of on your machine, so one stack orchestrates the rest. This is the "Spacelift managing Spacelift" pattern running for real, not just locally applied.

1. Get the trust policy, then create the AWS IAM role:
   - Cloud Integrations > AWS > Create integration. Name it, and the screen shows a ready-made trust-policy JSON with your instance's real AWS principal account ID and ExternalId pattern already filled in - copy it, then cancel out without saving. `meta/`'s own apply creates this integration under the same name; a manually saved one first will conflict with it.
   - AWS Console > IAM > Roles > Create role > Custom trust policy > paste the copied JSON > attach a permissions policy (`AdministratorAccess`/`PowerUserAccess` is fine for a throwaway test account) > name it > create > copy the resulting Role ARN.
2. Source Control > connect the VCS integration (same as Option B step 1).
3. Create one stack: project root `meta`, Terraform vendor, **Administrative = true**. Marking a stack administrative is what auto-injects `SPACELIFT_API_TOKEN` into its runs, so `provider "spacelift" {}` (meta/providers.tf, already zero-config) authenticates with no API key setup at all.
4. On that stack's **Environment** tab > **Add variable**, add `TF_VAR_vcs_repository=<owner>/<repo>` and `TF_VAR_aws_iam_role_arn=<role ARN from step 1>` (`TF_VAR_vcs_branch` only needed if you're not on `main`, it already defaults to that).
5. Trigger a run, review the plan, confirm apply. This single run creates the three workload stacks, the context, the six policies, the AWS integration, and the module registry entry - everything `meta/*.tf` defines.
6. Trigger `test-stack-foundation` first, then `test-stack-app` / `test-stack-ansible-config` (same ordering as the other two options - the meta stack doesn't auto-fire these).

## Manual/UI-only pieces worth exploring separately

These either need live infra context this scaffold cannot fabricate, or don't have a stable provider resource to script safely:

- **Drift detection**: enable a scheduled proposed run on `test-stack-foundation` (Stack settings > Scheduling), then manually change a tag in the AWS console and watch it get flagged.
- **Blueprints**: Blueprints > Create Blueprint in the UI, point it at `workloads/foundation` with a couple of input parameters (e.g. `name_prefix`), publish, then self-service a new stack from it.
- **Private worker pools**: needs a real worker (Docker container or ECS/Fargate task) running the Spacelift launcher and polling your account. Worth doing once the above is solid, mainly to see how `worker_pool_id` on a stack changes behavior versus the shared public workers.
- **Spaces and RBAC**: create a `test` space, move these three stacks into it, then test how login policy and space-level access control interact.

## Teardown

Destroy `app` and `ansible-config` stacks first (their state references `foundation`'s bucket), then `foundation`.

- Option A (`meta/`): `terraform destroy` inside `meta/` to remove the Spacelift-side resources themselves.
- Option B (manual): delete the three stacks, the context, the six policies, the AWS integration, and the registered module through the UI, in that order.
- Option C (administrative stack): trigger a destroy run on the meta stack itself; it tears down the context, policies, AWS integration, and module registry entry it created.
