variable "redis_name" { type = string }
variable "engine_version" { type = string }
variable "node_type" { type = string }
variable "num_nodes" { type = number }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "tags" { type = map(string) }