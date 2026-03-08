variable "project_name" { type = string }
variable "environment"  { type = string }
variable "vpc_cidr"     { type = string }
variable "azs"          { type = list(string) }

variable "public_subnets"       { type = list(string) }
variable "private_app_subnets"  { type = list(string) }
variable "data_subnets"         { type = list(string) }

variable "enable_nat_gateway" {
  description = "Create NAT per AZ (true for prod, false for cheap dev)"
  type        = bool
  default     = true
}