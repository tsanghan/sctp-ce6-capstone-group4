module "eks-kubeconfig" {
  source = "../eks-kubeconfig"
  # version      = "2.0.0"
  cluster_name = var.cluster_name
  region       = var.region
}

resource "local_file" "kubeconfig" {
  content         = module.eks-kubeconfig.kubeconfig
  filename        = "kubeconfig_${var.cluster_name}"
  file_permission = "0600"

  provisioner "local-exec" {
    command = "test -d ~/.kube || mkdir ~/.kube ; touch ~/.kube/config; rm ~/.kube/config ; cp kubeconfig_${var.cluster_name} ~/.kube/config"
  }
}