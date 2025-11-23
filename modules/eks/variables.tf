variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "eks_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "vpc_id" {
  description = "ID of the VPC where the EKS cluster will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for EKS control plane and worker ENIs"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for load balancers"
  type        = list(string)
}

variable "node_min_size" {
  description = "Minimum number of instances for the managed node group"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of instances for the managed node group"
  type        = number
  default     = 3
}

variable "node_desired_size" {
  description = "Desired number of instances for the managed node group"
  type        = number
  default     = 2
}

variable "node_instance_types" {
  description = "Instance types to use for the managed node group"
  type        = list(string)
  default     = ["t3.small"]
}

variable "tags" {
  description = "Tags to apply to the EKS resources"
  type        = map(string)
  default     = {}
}