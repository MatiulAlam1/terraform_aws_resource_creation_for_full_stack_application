include "root" { path = find_in_parent_folders() }
dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id = "mock-vpc"
    private_subnet_ids = ["mock-subnet"]
  }
}
terraform { source = "../../../modules//mq" }
inputs = {
  vpc_id             = dependency.vpc.outputs.vpc_id
  private_subnet_ids = dependency.vpc.outputs.private_subnet_ids
  mq_name            = "my-mq-prod"
  engine_version     = "3.13"
  instance_type      = "mq.t3.micro"
  username           = "user"
  password           = "devpassword123"
  tags               = { Environment = "prod" }
}
