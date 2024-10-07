terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.61.0"
    }
    # helm = {
    #   source  = "hashicorp/helm"
    #   version = "2.15.0"
    # }
    http = {
      source  = "hashicorp/http"
      version = "3.4.4"
    }
    # kubectl = {
    #   source  = "alekc/kubectl"
    #   version = ">= 2.0.0"
    # }
    null = {
      source  = "hashicorp/null"
      version = "3.2.3"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.12.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.2"
    }
    # flux = {
    #   source  = "fluxcd/flux"
    #   version = ">= 1.2"
    # }
    # github = {
    #   source  = "integrations/github"
    #   version = ">= 6.1"
    # }
    # kubernetes = {
    #   source  = "hashicorp/kubernetes"
    #   version = "2.32.0"
    # }
  }

  required_version = ">= 1.7.0"
}

provider "aws" {
  region = var.region
  default_tags {
    tags = var.tags
  }
}

# provider "helm" {
#   kubernetes {
#     host                   = module.make_eks.cluster_endpoint
#     cluster_ca_certificate = base64decode(module.make_eks.cluster_certificate_authority_data)
#     exec {
#       api_version = "client.authentication.k8s.io/v1"
#       args        = ["eks", "get-token", "--cluster-name", module.make_eks.cluster_name]
#       command     = "aws"
#     }
#     # token                  = data.aws_eks_cluster_auth.main.token
#   }
# }

# provider "kubectl" {
#   host                   = module.make_eks.cluster_endpoint
#   apply_retry_count      = 15
#   cluster_ca_certificate = base64decode(module.make_eks.cluster_certificate_authority_data)
#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     args        = ["eks", "get-token", "--cluster-name", module.make_eks.cluster_name]
#     command     = "aws"
#   }
#   load_config_file = false
#   # token                  = data.aws_eks_cluster_auth.main.token
# }

# provider "flux" {
#   kubernetes = {
#     host                   = module.make_eks.cluster_endpoint
#     cluster_ca_certificate = base64decode(module.make_eks.cluster_certificate_authority_data)
#     exec = {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       args        = ["eks", "get-token", "--cluster-name", module.make_eks.cluster_name]
#       command     = "aws"
#     }
#   }
#   git = {
#     url = "https://github.com/${var.github_org}/${var.github_repository}.git"
#     http = {
#       username = "git" # This can be any string when using a personal access token
#       password = var.github_token
#     }
#   }
# }

# provider "github" {
#   owner = var.github_org
#   token = var.github_token
# }

# provider "kubernetes" {
#   host                   = module.make_eks.cluster_endpoint
#   cluster_ca_certificate = base64decode(module.make_eks.cluster_certificate_authority_data)
#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     args        = ["eks", "get-token", "--cluster-name", module.make_eks.cluster_name]
#     command     = "aws"
#   }
# }
