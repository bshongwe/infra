output "cluster_id"             { value = module.eks.cluster_id }
output "cluster_endpoint"       { value = module.eks.cluster_endpoint }
output "cluster_ca_certificate" { value = module.eks.cluster_certificate_authority_data }
output "cluster_security_group_id" { value = module.eks.cluster_security_group_id }
output "oidc_provider_arn"      { value = module.eks.oidc_provider_arn }  # For IRSA
output "cluster_autoscaler_policy_arn" { value = aws_iam_policy.cluster_autoscaler.arn }