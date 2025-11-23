output "argocd_namespace" { value = helm_release.argocd.namespace }
output "istio_version" { value = helm_release.istiod.version }