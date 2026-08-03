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

1. Create the AWS IAM role Spacelift will assume:
   - Trust policy: principal is Spacelift's AWS account, condition on the external ID Spacelift generates for this integration (see `docs.spacelift.io/integrations/cloud-providers/aws`, `spacelift_aws_integration_attachment_external_id` data source if you want to fully automate this later).
   - Permissions: S3, IAM (scoped to the `sk-spacelift-test-*` role/policy names), SSM Parameter Store, CloudWatch Logs.
   - For a first pass you can attach `PowerUserAccess` scoped down later; this is a throwaway test account pattern, not a production one.
2. Push this repo to GitHub (or your VCS of choice) and connect it to Spacelift under Source Control if not already connected.
3. `cd meta`, set `vcs_repository`, `vcs_branch`, `aws_iam_role_arn` (either via `terraform.tfvars` or `-var`), export an administrative Spacelift API key (`SPACELIFT_API_KEY_ENDPOINT`, `SPACELIFT_API_KEY_ID`, `SPACELIFT_API_KEY_SECRET`), then `terraform init && terraform plan`.
4. Apply. This creates the three stacks, the context, the policies, the dependency wiring, and the AWS integration attachments.
5. Trigger a run on `test-stack-foundation` first (it has no dependencies). Once it completes with an apply phase, its outputs become available and `test-stack-app` / `test-stack-ansible-config` can be triggered.
6. Optional: once this is stable, point a fourth Spacelift stack at `meta/` itself with a Space Admin role attachment, so future changes to this file are applied through Spacelift rather than locally. This is the fully self-managing setup Spacelift's own docs describe.

## Manual/UI-only pieces worth exploring separately

These either need live infra context this scaffold cannot fabricate, or don't have a stable provider resource to script safely:

- **Drift detection**: enable a scheduled proposed run on `test-stack-foundation` (Stack settings > Scheduling), then manually change a tag in the AWS console and watch it get flagged.
- **Blueprints**: Blueprints > Create Blueprint in the UI, point it at `workloads/foundation` with a couple of input parameters (e.g. `name_prefix`), publish, then self-service a new stack from it.
- **Private worker pools**: needs a real worker (Docker container or ECS/Fargate task) running the Spacelift launcher and polling your account. Worth doing once the above is solid, mainly to see how `worker_pool_id` on a stack changes behavior versus the shared public workers.
- **Spaces and RBAC**: create a `test` space, move these three stacks into it, then test how login policy and space-level access control interact.

## Teardown

Destroy `app` and `ansible-config` stacks first (their state references `foundation`'s bucket), then `foundation`, then `terraform destroy` inside `meta/` to remove the Spacelift-side resources themselves.
