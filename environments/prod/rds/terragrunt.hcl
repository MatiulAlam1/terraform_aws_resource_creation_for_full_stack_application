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
terraform { source = "../../../modules//rds" }
inputs = {
  vpc_id             = dependency.vpc.outputs.vpc_id
  vpc_cidr           = dependency.vpc.outputs.vpc_cidr
  private_subnet_ids = dependency.vpc.outputs.private_subnet_ids
  rds_count          = 2
  rds_identifier     = "my-rds-prod"
  rds_instance_class = "db.t4g.small"
  rds_storage        = 20
  db_name            = "devdb"
  db_username        = "dbadmin"
  db_password        = "devpassword"  # Use Secrets Manager in prod
  tags               = { Environment = "prod" }
}
