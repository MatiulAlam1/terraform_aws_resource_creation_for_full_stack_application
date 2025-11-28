variable "vpc_name" { type = string }
variable "vpc_cidr" { type = string }
variable "az_count" {
  type    = number
  default = 3
}
variable "private_subnets" { type = list(string) }
variable "public_subnets" { type = list(string) }
variable "single_nat_gateway" { type = bool }
variable "tags" { type = map(string) }