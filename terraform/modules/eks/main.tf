data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket         = "platform-tf-state"
    key            = "${var.environment}/terraform.tfstate"
    region         = var.aws_region
    dynamodb_table = "platform-tf-locks"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.15.1"  # Latest as of March 2026

  cluster_name    = "${var.project_name}-${var.environment}"
  cluster_version = var.kubernetes_version  # e.g. "1.31"

  vpc_id     = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.vpc.outputs.private_app_subnet_ids  # Private subnets only

  # Control plane access - secure by default
  cluster_endpoint_public_access  = false
  cluster_endpoint_private_access = true

  # Enable control plane logging
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # IRSA - required for addons & services
  enable_irsa = true

  # Managed node groups
  eks_managed_node_groups = {
    general = {
      name           = "general"
      instance_types = ["m7g.large", "m6g.large"]  # Graviton for cost/perf
      min_size       = var.min_nodes_general
      max_size       = var.max_nodes_general
      desired_size   = var.desired_nodes_general

      # IMDSv2 required for security
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"  # IMDSv2
        http_put_response_hop_limit = 2
      }

      # Tags for Cluster Autoscaler discovery
      tags = {
        "k8s.io/cluster-autoscaler/enabled"                = "true"
        "k8s.io/cluster-autoscaler/${var.project_name}-${var.environment}" = "owned"
      }
    }

    # Placeholder for compute/ML workloads (e.g., GPU later)
    compute = {
      name           = "compute"
      instance_types = ["c7g.2xlarge"]
      min_size       = 0
      max_size       = 5
      desired_size   = 0

      taints = [{
        key    = "workload-type"
        value  = "compute-intensive"
        effect = "NO_SCHEDULE"
      }]
    }
  }

  # IAM roles & policies
  cluster_additional_security_group_ids = [data.terraform_remote_state.vpc.outputs.vpc_security_group_id]

  tags = {
    Environment = var.environment
    Terraform   = "true"
    Project     = var.project_name
  }
}

# IAM policy for Cluster Autoscaler (attach to IRSA role later)
resource "aws_iam_policy" "cluster_autoscaler" {
  name        = "${var.project_name}-cluster-autoscaler-${var.environment}"
  description = "Policy for Kubernetes Cluster Autoscaler"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeLaunchTemplateVersions"
        ]
        Resource = "*"
      }
    ]
  })
}