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
terraform { source = "../../../modules//msk" }
inputs = {
  vpc_id             = dependency.vpc.outputs.vpc_id
  vpc_cidr           = dependency.vpc.outputs.vpc_cidr
  private_subnet_ids = dependency.vpc.outputs.private_subnet_ids
  msk_name           = "my-msk-test"
  kafka_version      = "3.7.x"
  broker_nodes       = 3  # Must match number of AZs
  broker_instance_type = "kafka.t3.small"
  broker_volume_size = 10
  tags               = { Environment = "test" }
}
