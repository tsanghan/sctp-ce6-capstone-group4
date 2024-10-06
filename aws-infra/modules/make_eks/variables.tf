variable "eks_cluster_name" {
  type    = string
  default = ""
}

variable "eks_cluster_version" {
  type    = string
  default = ""
}

variable "ami_type" {
  type    = string
  default = ""
}

variable "instance_type" {
  type    = string
  default = ""
}

variable "ami_release_version" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "vpc_id" {
  type    = string
  default = ""
}

variable "subnet_ids" {
  type    = list(string)
  default = []
}

variable "oidc_fully_qualified_audiences" {
  type    = list(string)
  default = []
}

variable "role_policy_arns" {
  type    = list(string)
  default = []
}

variable "cluster_endpoint_public_access_cidrs" {
  type    = list(string)
  default = []
}



