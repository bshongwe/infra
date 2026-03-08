terraform {
  required_version = ">= 1.6"
}

module "vpc" {
  source = "../../modules/vpc"

  project_name    = "cloud-risk-platform"
  environment     = "dev"
  vpc_cidr        = "10.0.0.0/16"
  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]

  public_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_app_subnets = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  data_subnets        = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]

  enable_nat_gateway = false  # Save costs in dev; set true in prod
}