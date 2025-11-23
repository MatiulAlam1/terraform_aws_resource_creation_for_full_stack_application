include "root" { path = find_in_parent_folders() }
dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id = "mock-vpc"
    private_subnet_ids = ["mock-subnet"]
  }
}
terraform { source = "../../../modules//elasticache" }
inputs = {
  vpc_id             = dependency.vpc.outputs.vpc_id
  private_subnet_ids = dependency.vpc.outputs.private_subnet_ids
  redis_name         = "my-redis-test"
  engine_version     = "7.1"
  node_type          = "cache.t4g.small"
  num_nodes          = 1  # Single for test
  tags               = { Environment = "test" }
}
