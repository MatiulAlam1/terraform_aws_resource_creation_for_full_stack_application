data "aws_availability_zones" "available" {
  state = "available"  # Filter for available AZs
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.14.0"  # Latest as of 2025

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = true
  single_nat_gateway = var.single_nat_gateway  # Cheaper for dev/test

  tags = var.tags
}