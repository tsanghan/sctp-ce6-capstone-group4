variable "name" {
  type    = string
  default = "tsanghan-ce6"
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default = {
    created-by = "tsanghan-ce6"
    env        = "tsanghan-ce6"
    # Name       = "tsanghan-ce6"
  }
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "tsanghan-ce6"
}

variable "cluster_version" {
  description = "EKS cluster version."
  type        = string
  default     = "1.31"
}

variable "ami_type" {
  description = "Type of Amazon Machine Image (AMI) associated with the EKS Node Group. Group. See the [AWS documentation](https://docs.aws.amazon.com/eks/latest/APIReference/API_Nodegroup.html#AmazonEKS-Type-Nodegroup-amiType) for valid values"
  type        = string
  # default     = "AL2_x86_64"
  default = "AL2023_x86_64_STANDARD"
}

variable "ami_release_version" {
  description = "Default EKS AMI release version for node groups"
  type        = string
  default     = "1.31.0-20240928"
}

variable "vpc_cidr" {
  description = "Defines the CIDR block used on Amazon VPC created for Amazon EKS."
  type        = string
  default     = "10.42.0.0/16"
}

variable "instance_type" {
  type    = string
  default = "t3.large"
}

variable "oidc_fully_qualified_audiences" {
  type = list(string)
  default = [
    "sts.amazonaws.com"
  ]
}

variable "role_policy_arns" {
  type = list(string)
  default = [
    "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]
}

# variable "gateway_api" {
#   type = list(string)
#   default = [
#     "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.1.0/config/crd/standard/gateway.networking.k8s.io_gatewayclasses.yaml",
#     "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.1.0/config/crd/standard/gateway.networking.k8s.io_gateways.yaml",
#     "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.1.0/config/crd/standard/gateway.networking.k8s.io_httproutes.yaml",
#     "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.1.0/config/crd/standard/gateway.networking.k8s.io_referencegrants.yaml",
#     "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.1.0/config/crd/standard/gateway.networking.k8s.io_grpcroutes.yaml",
#     "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.1.0/config/crd/experimental/gateway.networking.k8s.io_tlsroutes.yaml",
#     "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.1.0/config/crd/experimental/gateway.networking.k8s.io_backendtlspolicies.yaml"
#   ]
# }

variable "region" {
  type    = string
  default = "ap-southeast-1"
}

variable "github_org" {
  type    = string
  default = "tsanghan"
}

variable "github_repository" {
  type    = string
  default = "fleet-infra"
}

variable "github_token" {
  type      = string
  sensitive = true
  default   = ""
}

variable "hosted_zone" {
  type    = string
  default = "sctp-sandbox.com."
}


variable "MYIP" {
  type    = string
  default = ""
}

# variable "log_groups" {
#   type = list(string)
#   default = [
#     "/aws/containerinsights/tsanghan-ce6/application",
#     "/aws/containerinsights/tsanghan-ce6/dataplane",
#     "/aws/containerinsights/tsanghan-ce6/host",
#     "/aws/containerinsights/tsanghan-ce6/performance",
#   ]
# }

# variable "staging" {
#   type    = bool
#   default = true
# }

# variable "cert_manager" {
#   description = "cert-manager add-on configuration values"
#   type        = any
#   default     = {}
# }

# variable "cert_manager_route53_hosted_zone_arns" {
#   description = "List of Route53 Hosted Zone ARNs that are used by cert-manager to create DNS records"
#   type        = list(string)
#   default     = ["arn:aws:route53:::hostedzone/*"]
# }

# variable "external_dns_route53_zone_arns" {
#   description = "List of Route53 zones ARNs which external-dns will have access to create/manage records (if using Route53)"
#   type        = list(string)
#   default     = []
# }

# variable "external_dns" {
#   description = "external-dns add-on configuration values"
#   type        = any
#   default     = {}
# }