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

  # Enterprise standard tags
  tags = {
    Owner           = "platform-team"
    CostCenter      = "engineering"
    BusinessUnit    = "risk-management"
    DataClass       = "confidential"
    Compliance      = "sox,pci"
    BackupPolicy    = "daily"
    MaintenanceWindow = "sun:03:00-sun:05:00"
    CreatedBy       = "terraform"
    Repository      = "infra"
  }
}

module "eks" {
  source = "../../modules/eks"

  project_name    = "cloud-risk-platform"
  environment     = "dev"
  aws_region      = var.aws_region

  kubernetes_version = "1.31"

  min_nodes_general     = 1
  max_nodes_general     = 5
  desired_nodes_general = 1
}

# Outputs for next phases (e.g., kubeconfig generation)
output "eks_cluster_endpoint" { value = module.eks.cluster_endpoint }
output "eks_oidc_provider_arn" { value = module.eks.oidc_provider_arn }