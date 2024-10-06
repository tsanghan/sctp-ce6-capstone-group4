locals {
  private_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 3, k + 3)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 3, k)]
  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.1"

  name = var.cluster_name
  cidr = var.vpc_cidr

  azs                   = local.azs
  public_subnets        = local.public_subnets
  private_subnets       = local.private_subnets
  private_subnet_names  = ["Private-Subnet-1a", "Private-Subnet-1b", "Private-Subnet-1c"]
  public_subnet_names   = ["Public-Subnet-1a", "Public-Subnet-1b", "Public-Subnet-1c"]
  public_subnet_suffix  = "Public"
  private_subnet_suffix = "Private"

  enable_nat_gateway   = true
  create_igw           = true
  enable_dns_hostnames = true
  single_nat_gateway   = true

  # Manage so we can name
  manage_default_network_acl    = true
  default_network_acl_name      = "nacl-default"
  default_network_acl_tags      = { Extra = "nacl-default" }
  manage_default_route_table    = true
  default_route_table_name      = "rtb-default"
  default_route_table_tags      = { Extra = "rtb-default" }
  manage_default_security_group = true
  default_security_group_name   = "sg-default"
  default_security_group_tags   = { Extra = "sg-default" }

  igw_tags                 = { Name = "igw" }
  nat_gateway_tags         = { Name = "nat-gw" }
  private_route_table_tags = { Name = "rtb-private" }
  public_route_table_tags  = { Name = "rtb-public" }

  public_subnet_tags = merge(var.tags, {
    "kubernetes.io/role/elb" = "1"
  })
  private_subnet_tags = merge(var.tags, {
    "karpenter.sh/discovery" = var.cluster_name
  })

  tags = {
    VPC = var.name
  }
}
