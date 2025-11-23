variable "msk_name" { type = string }
variable "kafka_version" { type = string }
variable "broker_nodes" { type = number }
variable "broker_instance_type" { type = string }
variable "broker_volume_size" { type = number }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "tags" { type = map(string) }