include "root" { path = find_in_parent_folders() }
dependency "vpc" {
  config_path = "../vpc"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
  mock_outputs = {
    vpc_id = "mock-vpc"
    vpc_cidr = "10.0.0.0/16"
    private_subnet_ids = ["mock-subnet"]
  }
}
terraform { source = "../../../modules//elasticache" }
inputs = {
  vpc_id             = dependency.vpc.outputs.vpc_id
  vpc_cidr           = dependency.vpc.outputs.vpc_cidr
  private_subnet_ids = dependency.vpc.outputs.private_subnet_ids
  redis_name         = "my-redis-dev-${get_env("AWS_REGION", "ap-south-1")}"
  engine_version     = "7.1"
  node_type          = "cache.t4g.small"
  num_nodes          = 1
  tags               = { Environment = "dev" }
}
