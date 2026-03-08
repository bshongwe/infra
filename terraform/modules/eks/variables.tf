variable "project_name"    { type = string }
variable "environment"     { type = string }
variable "aws_region"      { type = string }
variable "kubernetes_version" { type = string default = "1.31" }

variable "min_nodes_general"     { default = 1 }
variable "max_nodes_general"     { default = 10 }
variable "desired_nodes_general" { default = 2 }