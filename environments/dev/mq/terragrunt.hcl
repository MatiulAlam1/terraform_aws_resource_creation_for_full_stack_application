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
terraform { source = "../../../modules//mq" }
inputs = {
  vpc_id             = dependency.vpc.outputs.vpc_id
  vpc_cidr           = dependency.vpc.outputs.vpc_cidr
  private_subnet_ids = dependency.vpc.outputs.private_subnet_ids
  mq_name            = "my-mq-dev"
  engine_version     = "3.13"
  instance_type      = "mq.t3.micro"
  username           = "user"
  password           = "devpassword123"
  tags               = { Environment = "dev" }
}
