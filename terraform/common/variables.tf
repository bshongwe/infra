variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "af-south-1"
}

variable "project_name" {
  description = "Project prefix"
  type        = string
  default     = "cloud-risk-platform"
}

variable "environment" {
  description = "Environment name (dev/staging/production)"
  type        = string
}