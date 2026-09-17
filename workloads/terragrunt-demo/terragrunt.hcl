# No `source` block: Terragrunt runs against the .tf files sitting next to
# this file. Spacelift owns the backend (the stack sets
# use_state_management = true), so there is no remote_state block either -
# that is the whole point of the setting.

inputs = {
  name_prefix = get_env("TF_VAR_name_prefix", "sk-spacelift-test")
  aws_region  = get_env("TF_VAR_aws_region", "eu-west-1")
}
