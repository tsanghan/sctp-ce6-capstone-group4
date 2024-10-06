module "iam-assumable-role-with-oidc" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.44.0"

  create_role = true

  role_name = "AmazonEKS_Observability_Role"

  tags = merge(var.tags, {
    Role = "AmazonEKS_Observability_Role"
  })

  provider_url = module.eks.oidc_provider

  oidc_fully_qualified_audiences = var.oidc_fully_qualified_audiences

  role_policy_arns = var.role_policy_arns
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name                             = var.eks_cluster_name
  cluster_version                          = var.eks_cluster_version
  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true
  cluster_endpoint_public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
  dataplane_wait_duration                  = "240s"


  cluster_enabled_log_types = ["audit", "api", "authenticator", "controllerManager", "scheduler"]
  # create_cloudwatch_log_group = false
  cloudwatch_log_group_retention_in_days = 1

  cluster_addons = {
    vpc-cni = {
      before_compute       = true
      most_recent          = true
      configuration_values = file("${path.module}/json/vpc-cni.json")
    }
    amazon-cloudwatch-observability = {
      service_account_role_arn = module.iam-assumable-role-with-oidc.iam_role_arn
      configuration_values     = file("${path.module}/json/amazon-cloudwatch-observability.json")
    }
    #    eks-pod-identity-agent = {}
  }

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  create_cluster_security_group = false
  create_node_security_group    = false

  eks_managed_node_groups = {
    tsanghan-ce6 = {
      ami_type             = var.ami_type
      instance_types       = [var.instance_type]
      force_update_version = true
      release_version      = var.ami_release_version
      # capacity_type        = "SPOT"

      min_size     = 2
      max_size     = 4
      desired_size = 2

      update_config = {
        max_unavailable_percentage = 50
      }

      # iam_role_additional_policies = {
      #   name = data.aws_iam_policy.cloudwatchagentserverpolicy.arn
      # }

      # For Cilium
      taints = [
        {
          key    = "node.cilium.io/agent-not-ready"
          value  = "true"
          effect = "NO_EXECUTE"
        }
      ]

      labels = merge(var.tags, {
        capstone-project = "yes"
      })
    }
  }

  create_kms_key            = false
  cluster_encryption_config = {}

  tags = merge(var.tags, {
    "karpenter.sh/discovery" = var.eks_cluster_name
    EKS                      = "tsanghan-ce6"
  })

}
