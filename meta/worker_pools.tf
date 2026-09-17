# Worker pools. Creating the pool is enough to populate the Worker Pools UI;
# it stays empty until you run a launcher against it. The provider generates
# the keypair and returns `config` - the base64 token the launcher needs:
#
#   terraform output -raw worker_pool_config
#   docker run -e SPACELIFT_TOKEN=... -e SPACELIFT_POOL_PRIVATE_KEY=... \
#     public.ecr.aws/spacelift/launcher
#
# Stacks only point at the pool when var.attach_worker_pool is true; with no
# worker polling, runs on a private pool queue forever.

resource "spacelift_worker_pool" "test" {
  name                      = "test-stack-worker-pool"
  description               = "Private worker pool for this playground. Empty until you start a launcher."
  space_id                  = spacelift_space.test_stack.id
  labels                    = ["test-stack"]
  drift_detection_run_limit = 2
}

# VCS agent pools are the equivalent for reaching a self-hosted VCS that
# isn't exposed to the internet. Same story: the pool exists, the agent
# doesn't until you run one.
resource "spacelift_vcs_agent_pool" "test" {
  name        = "test-stack-vcs-agent-pool"
  description = "Only needed for a VCS behind a firewall; created here so the screen isn't empty"
}
