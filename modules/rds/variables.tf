variable "rds_count" {
  description = "Number of RDS instances to create"
  type        = number
  default     = 1
}

variable "rds_identifier" {
  description = "RDS instance identifier"
  type        = string
}

variable "rds_instance_class" {
  description = "Instance class for the RDS instance (e.g. db.t3.medium)"
  type        = string
}

variable "rds_storage" {
  description = "Allocated storage (in GB) for the RDS instance"
  type        = number
}

variable "db_name" {
  description = "Initial database name to create on the RDS instance"
  type        = string
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
}

variable "db_password" {
  description = "Master password for the database"
  type        = string
  sensitive   = true
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the RDS subnet group"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID where the RDS instance and security group will be created"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block for security group rules"
  type        = string
}

variable "tags" {
  description = "Tags to apply to RDS resources"
  type        = map(string)
  default     = {}
}