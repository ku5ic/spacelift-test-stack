output "space_ids" {
  description = "Slugs of the four spaces this configuration creates"
  value = {
    test_stack  = spacelift_space.test_stack.id
    development = spacelift_space.development.id
    staging     = spacelift_space.staging.id
    production  = spacelift_space.production.id
  }
}

output "stack_ids" {
  description = "Every stack this configuration creates, including the gated ones"
  value = merge(
    {
      foundation     = spacelift_stack.foundation.id
      app            = spacelift_stack.app.id
      ansible_config = spacelift_stack.ansible_config.id
      tofu           = spacelift_stack.tofu.id
      terragrunt     = spacelift_stack.terragrunt.id
    },
    var.enable_extra_vendor_stacks ? {
      pulumi         = spacelift_stack.pulumi[0].id
      cloudformation = spacelift_stack.cloudformation[0].id
      kubernetes     = spacelift_stack.kubernetes[0].id
    } : {},
  )
}

output "context_ids" {
  value = {
    common = spacelift_context.common.id
    hooks  = spacelift_context.hooks.id
  }
}

output "aws_integration_id" {
  value = spacelift_aws_integration.test.id
}

output "module_id" {
  value = spacelift_module.s3_bucket.id
}

output "blueprint_id" {
  value = spacelift_blueprint.workload_stack.id
}

output "worker_pool_config" {
  description = "Base64 token the launcher needs. Feed it to the launcher as SPACELIFT_TOKEN."
  value       = spacelift_worker_pool.test.config
  sensitive   = true
}

output "worker_pool_private_key" {
  description = "Feed to the launcher as SPACELIFT_POOL_PRIVATE_KEY"
  value       = spacelift_worker_pool.test.private_key
  sensitive   = true
}
