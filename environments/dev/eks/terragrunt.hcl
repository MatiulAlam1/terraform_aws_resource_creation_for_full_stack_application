include "root" {
  path = find_in_parent_folders()
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id             = "mock-vpc"
    private_subnet_ids = ["mock-subnet"]
    public_subnet_ids  = ["mock-subnet"]
  }
}

terraform {
  source = "../../../modules//eks"
}

inputs = {
  vpc_id              = dependency.vpc.outputs.vpc_id
  private_subnet_ids  = dependency.vpc.outputs.private_subnet_ids
  public_subnet_ids   = dependency.vpc.outputs.public_subnet_ids
  eks_cluster_name    = "my-eks-dev"
  eks_version         = "1.32"
  node_min_size       = 2
  node_max_size       = 3
  node_desired_size   = 2
  node_instance_types = ["t3.small"]
  tags                = { Environment = "dev" }
}
