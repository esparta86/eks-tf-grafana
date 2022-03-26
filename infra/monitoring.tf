
resource "kubernetes_namespace" "prometheus" {
 depends_on = [
   aws_eks_cluster.eks-deployment, aws_eks_node_group.private-nodes
 ]
  metadata {
    name = var.namespace_prometheus
  }
}

resource "helm_release" "prometheus" {
  depends_on = [
    kubernetes_namespace.prometheus
  ]
  chart = "prometheus"
  name = "prometheus"
  namespace = var.namespace_prometheus
  repository = "https://prometheus-community.github.io/helm-charts"

  wait = true

  version = "15.5.4"

  set {
    name = "server.persistentVolume.storageClass"
    value = "gp2"
  }

  set {
    name = "alertmanager.persistentVolume.storageClass"
    value = "gp2"
  }


}