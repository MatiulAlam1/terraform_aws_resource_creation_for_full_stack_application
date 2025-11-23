// Outputs exported by the VPC module.
// The ID of the created VPC.
output "vpc_id" {
	value = module.vpc.vpc_id
}

// A list of private subnet IDs created in the VPC.
output "private_subnet_ids" {
	value = module.vpc.private_subnets
}

// A list of public subnet IDs created in the VPC.
output "public_subnet_ids" {
	value = module.vpc.public_subnets
}