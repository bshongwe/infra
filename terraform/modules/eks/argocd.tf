resource "helm_release" "argocd" {
  name       = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "platform"           # Namespace
  create_namespace = true
  version    = "7.6.8"              # Latest stable as of March 2026

  # Minimal secure defaults
  set {
    name  = "server.service.type"
    value = "ClusterIP"             # Will expose via ALB Ingress later
  }

  set {
    name  = "configs.secret.argocdServerAdminPassword"
    value = ""                      # Will update later
  }

  set_sensitive {
    name  = "configs.secret.argocdServerAdminPassword"
    value = random_password.argocd_admin.result  # See below
  }

  depends_on = [module.eks]
}

# Generate initial admin password (change immediately after first login)
resource "random_password" "argocd_admin" {
  length           = 16
  special          = true
  override_special = "!@#$%^&*()_+-="
}

output "argocd_initial_admin_password" {
  value     = random_password.argocd_admin.result
  sensitive = true
}