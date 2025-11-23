resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "5.51.6"
  namespace        = "argocd"
  create_namespace = true
  timeout          = 600
  wait             = false

  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }
}

resource "helm_release" "istio_base" {
  name             = "istio-base"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "base"
  version          = "1.23.2"
  namespace        = "istio-system"
  create_namespace = true
}

resource "helm_release" "istiod" {
  name             = "istiod"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "istiod"
  version          = "1.23.2"
  namespace        = "istio-system"
  create_namespace = true
  timeout          = 600
  wait             = false

  depends_on = [helm_release.istio_base]
}
