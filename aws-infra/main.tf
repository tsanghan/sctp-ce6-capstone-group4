# locals {
#   create_role = true
# }

data "aws_caller_identity" "current" {}

# data "aws_partition" "current" {
#   count = local.create_role ? 1 : 0
# }

data "aws_route53_zone" "selected" {
  name = var.hosted_zone
}

# data "aws_eks_cluster_auth" "main" {
#   name = var.cluster_name
# }

data "http" "myip" {
  url = "http://api.ipify.org"
}

module "dashboards" {
  source = "./modules/dashboards"

  cluster_name = var.cluster_name
  region       = var.region
  account_id   = data.aws_caller_identity.current.account_id

  depends_on = [module.make_eks]
}

module "alarms" {
  source = "./modules/alarms"

  eks_cluster_name = var.cluster_name

  depends_on = [module.make_eks]
}

module "make_eks" {
  source = "./modules/make_eks"

  vpc_id                               = module.vpc.vpc_id
  subnet_ids                           = module.vpc.private_subnets
  eks_cluster_name                     = var.cluster_name
  eks_cluster_version                  = var.cluster_version
  ami_type                             = var.ami_type
  instance_type                        = var.instance_type
  ami_release_version                  = var.ami_release_version
  oidc_fully_qualified_audiences       = var.oidc_fully_qualified_audiences
  role_policy_arns                     = var.role_policy_arns
  cluster_endpoint_public_access_cidrs = ["${data.http.myip.response_body}/32", "${var.MYIP}/32"]
  tags                                 = var.tags

}

module "make_kubeconfig" {
  source = "./modules/make_kubeconfig"

  cluster_name = var.cluster_name
  region       = var.region

  depends_on = [module.make_eks]
}

# module "eks_blueprints_addons" {
#   source  = "aws-ia/eks-blueprints-addons/aws"
#   version = "~> 1.0" #ensure to update this to the latest/desired version

#   cluster_name                = module.make_eks.cluster_name
#   cluster_endpoint            = module.make_eks.cluster_endpoint
#   cluster_version             = module.make_eks.cluster_version
#   oidc_provider_arn           = module.make_eks.oidc_provider_arn
#   create_kubernetes_resources = false

#   eks_addons = {
#     # aws-ebs-csi-driver = {
#     #   most_recent = true
#     # }
#     # coredns = {
#     #   most_recent = true
#     # }
#     # vpc-cni = {
#     #   most_recent = true
#     # }
#     # kube-proxy = {
#     #   most_recent = true
#     # }
#     # cert-manager = {
#     #   chart_version    = "v1.15.3"
#     #   namespace        = "cert-manager"
#     #   create_namespace = true
#     # }
#   }

#   #   enable_aws_load_balancer_controller    = true
#   #   enable_cluster_proportional_autoscaler = true
#   #   enable_karpenter                       = true
#   #   enable_kube_prometheus_stack           = true
#   #   enable_metrics_server                  = true
#   #   enable_external_dns                    = true
#   enable_cert_manager                   = true
#   enable_external_dns                   = true
#   cert_manager_route53_hosted_zone_arns = [data.aws_route53_zone.selected.arn]
#   external_dns_route53_zone_arns        = [data.aws_route53_zone.selected.arn]

#   tags = merge(var.tags, {
#     Name        = var.name
#     Environment = "dev"
#   })

#   depends_on = [module.make_eks]
# }

# resource "flux_bootstrap_git" "this" {
#   embedded_manifests = true
#   path               = "clusters/my-cluster"
#   timeouts = {
#     create = "30s"
#   }

#   depends_on = [module.make_eks]
# }

# resource "kubectl_manifest" "role" {
#   yaml_body = file("${path.module}/yaml/role.yaml")

#   depends_on = [module.make_eks]
# }

# resource "kubectl_manifest" "rolebinding" {
#   yaml_body = file("${path.module}/yaml/rolebinding.yaml")

#   depends_on = [module.make_eks]
# }

# resource "kubectl_manifest" "cluster_issuer_staging" {
#   count     = var.staging ? 1 : 0
#   yaml_body = templatefile("${path.module}/yaml/cluster-issuer-staging.tftpl", { cert_manager_role_arn = module.eks_blueprints_addons.cert_manager.iam_role_arn })

#   depends_on = [module.make_eks]
# }

# resource "kubectl_manifest" "cluster_issuer_production" {
#   count     = var.staging ? 0 : 1
#   yaml_body = templatefile("${path.module}/yaml/cluster-issuer-production.tftpl", { cert_manager_role_arn = module.eks_blueprints_addons.cert_manager.iam_role_arn })

#   depends_on = [module.make_eks]
# }

# locals {
#   create_cert_manager_irsa = true
#   partition                = try(data.aws_partition.current[0].partition, "*")
# }


module "cert-manager-irsa" {
  source = "./modules/irsa-cert-manager"

  role_name                             = "${var.name}-cert-manager-role"
  oidc_provider_arn                     = module.make_eks.oidc_provider_arn
  cert_manager_route53_hosted_zone_arns = [data.aws_route53_zone.selected.arn]
  namespace                             = "cert-manager"

  oidc_providers = {
    this = {
      provider_arn = module.make_eks.oidc_provider_arn
      # namespace is inherited from chart
      service_account = "cert-manager"
    }
  }
}

module "external-dns-irsa" {
  source = "./modules/irsa-external-dns"

  role_name                      = "${var.name}-external-dns-role"
  oidc_provider_arn              = module.make_eks.oidc_provider_arn
  external_dns_route53_zone_arns = [data.aws_route53_zone.selected.arn]


  oidc_providers = {
    this = {
      provider_arn = module.make_eks.oidc_provider_arn
      # namespace is inherited from chart
      namespace       = "external-dns"
      service_account = "external-dns"
    }
  }
}

resource "aws_route53_record" "caa" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = data.aws_route53_zone.selected.name
  type    = "CAA"
  ttl     = 60
  records = ["0 issue \"amazon.com\"", "128 issue \"letsencrypt.org\""]
}

resource "aws_eks_access_entry" "me" {
  cluster_name      = module.make_eks.cluster_name
  principal_arn     = data.aws_iam_user.me
  kubernetes_groups = ["system:masters"]
  type              = "STANDARD"
}

data "aws_iam_user" "me" {
  user_name = "tsanghan"
}