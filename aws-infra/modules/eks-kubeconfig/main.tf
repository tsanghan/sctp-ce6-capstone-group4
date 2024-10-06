data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "ephemeral" {
  name = var.cluster_name
}

locals {
  kubeconfig = yamlencode({
    apiVersion      = "v1"
    kind            = "Config"
    current-context = "terraform"
    clusters = [{
      name = data.aws_eks_cluster.this.id
      cluster = {
        certificate-authority-data = data.aws_eks_cluster.this.certificate_authority[0].data
        server                     = data.aws_eks_cluster.this.endpoint
      }
    }]
    contexts = [{
      name = "terraform"
      context = {
        cluster = data.aws_eks_cluster.this.id
        user    = "terraform"
      }
    }]
    users = [{
      name = "terraform"
      user = {
        exec = {
          apiVersion = "client.authentication.k8s.io/v1beta1"
          args       = ["--region", var.region, "eks", "get-token", "--cluster-name", data.aws_eks_cluster.this.id, "--output", "json"]
          command    = "aws"
        }
      }
    }]
  })
}
