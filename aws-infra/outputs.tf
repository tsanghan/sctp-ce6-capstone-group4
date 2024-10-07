output "cluster_iam_role_name" {
  value = module.make_eks.cluster_iam_role_name
}

# output "eks_node_group_policy" {
#   value = module.make_eks.eks_managed_node_groups["tsanghan-ce6"]
# }

output "oidc_provider" {
  value = module.make_eks.oidc_provider
}

output "oidc_provider_arn" {
  value = module.make_eks.oidc_provider_arn
}

output "eks_kubeconfig" {
  value     = module.make_kubeconfig.kubeconfig
  sensitive = true
}

output "cert_manager_irsa_iam_role_arn" {
  value = module.cert-manager-irsa.cert_manager_role_arn
}

output "external_dns_irsa_iam_role_arn" {
  value = module.external-dns-irsa.external_dns_role_arn
}
