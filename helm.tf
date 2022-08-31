
  
/* provider "helm" {
    kubernetes {
        host                   = data.aws_eks_cluster.cluster.endpoint
        cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
        token                  = data.aws_eks_cluster_auth.eks_cluster_auth.token
    }
}
module jenkins {
  source  = "terraform-module/release/helm"
  version = "2.6.0"

  namespace  = "jenkins"
  repository =  "https://charts.helm.sh/stable"

  app = {
    name          = "jenkins"
    version       = "1.5.0"
    chart         = "jenkins"
    force_update  = true
    wait          = false
    recreate_pods = false
    deploy        = 1
  }
  values = [{
    region                = var.region
    storage               = "4Gi"
  }]
  set = [
    {
      name  = "labels.kubernetes\\.io/name"
      value = "jenkins"
    },
    {
      name  = "service.labels.kubernetes\\.io/name"
      value = "jenkins"
    },
  ]

  set_sensitive = [
    {
      path  = "master.adminUser"
      value = "jenkins"
    },
  ]
} */