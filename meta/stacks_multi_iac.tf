# One stack per IaC vendor Spacelift supports, so the Create-stack vendor
# screens and the per-vendor run views all have a live example.
#
# OpenTofu and Terragrunt point at real workloads in this repo and apply
# cleanly with the same AWS integration as everything else. The rest need
# infrastructure this repo can't fabricate (a Pulumi backend, a CFN template
# bucket, a cluster), so they are gated behind var.enable_extra_vendor_stacks
# and exist to populate the UI, not to go green.

resource "spacelift_stack" "tofu" {
  name         = "test-stack-tofu"
  description  = "Same shape as the app stack, run through OpenTofu instead of Terraform"
  repository   = var.vcs_repository
  branch       = var.vcs_branch
  project_root = "workloads/tofu-demo"
  space_id     = spacelift_space.staging.id

  autodeploy = false
  labels     = ["test-stack", "opentofu", "aws"]

  opentofu {
    version                = "1.8.2"
    workflow_tool          = "OPENTOFU"
    workspace              = "default"
    use_smart_sanitization = true
    external_state_access  = false
  }
}

resource "spacelift_stack" "terragrunt" {
  name         = "test-stack-terragrunt"
  description  = "Terragrunt wrapper over the same S3 module, driving OpenTofu underneath"
  repository   = var.vcs_repository
  branch       = var.vcs_branch
  project_root = "workloads/terragrunt-demo"
  space_id     = spacelift_space.staging.id

  autodeploy = false
  labels     = ["test-stack", "terragrunt", "aws"]

  terragrunt {
    terragrunt_version                     = "0.67.16"
    terraform_version                      = "1.8.2"
    tool                                   = "OPEN_TOFU"
    use_run_all                            = false
    use_state_management                   = true
    use_smart_sanitization                 = true
    prefix_resource_names_with_module_name = false
  }
}

resource "spacelift_stack" "pulumi" {
  count = var.enable_extra_vendor_stacks ? 1 : 0

  name         = "test-stack-pulumi"
  description  = "Pulumi vendor example. Needs a reachable Pulumi state backend before a run will get past init."
  repository   = var.vcs_repository
  branch       = var.vcs_branch
  project_root = "workloads/pulumi-demo"
  space_id     = spacelift_space.staging.id

  autodeploy = false
  labels     = ["test-stack", "pulumi"]

  pulumi {
    login_url  = var.pulumi_login_url
    stack_name = "test-stack-pulumi"
  }
}

resource "spacelift_stack" "cloudformation" {
  count = var.enable_extra_vendor_stacks ? 1 : 0

  name         = "test-stack-cloudformation"
  description  = "CloudFormation vendor example. template_bucket must be an S3 bucket the AWS integration can write to."
  repository   = var.vcs_repository
  branch       = var.vcs_branch
  project_root = "workloads/cloudformation-demo"
  space_id     = spacelift_space.staging.id

  autodeploy = false
  labels     = ["test-stack", "cloudformation", "aws"]

  cloudformation {
    entry_template_file = "template.yaml"
    region              = var.aws_region
    stack_name          = "${var.name_prefix}-cfn"
    template_bucket     = var.cloudformation_template_bucket
  }
}

resource "spacelift_stack" "kubernetes" {
  count = var.enable_extra_vendor_stacks ? 1 : 0

  name         = "test-stack-kubernetes"
  description  = "Kubernetes vendor example. Needs a kubeconfig in the environment before a run will connect."
  repository   = var.vcs_repository
  branch       = var.vcs_branch
  project_root = "workloads/kubernetes-demo"
  space_id     = spacelift_space.staging.id

  autodeploy = false
  labels     = ["test-stack", "kubernetes"]

  kubernetes {
    namespace                = "default"
    kubectl_version          = "1.31.0"
    kubernetes_workflow_tool = "KUBERNETES"
  }
}
