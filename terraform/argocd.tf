# ---------------------------------------------------------------------------
# ArgoCD namespace
# ---------------------------------------------------------------------------

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.argocd_namespace
  }

  depends_on = [kind_cluster.this]
}

# ---------------------------------------------------------------------------
# ArgoCD — installed via Helm
# ---------------------------------------------------------------------------

resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version

  # Keep the server insecure locally so port-forward works without TLS issues
  set {
    name  = "server.extraArgs[0]"
    value = "--insecure"
  }

  # Enable server-side apply for CRD management
  set {
    name  = "crds.install"
    value = "true"
  }

  wait    = true
  timeout = 300

  depends_on = [kubernetes_namespace.argocd]
}

# ---------------------------------------------------------------------------
# ArgoCD AppProject — infrastructure
# Applied before the root app so ArgoCD can reference it immediately
# ---------------------------------------------------------------------------

resource "kubectl_manifest" "argocd_project_infrastructure" {
  yaml_body = file("${path.module}/../argocd/projects/infrastructure.yaml")

  depends_on = [helm_release.argocd]
}

resource "kubectl_manifest" "argocd_project_microservices" {
  yaml_body = file("${path.module}/../argocd/projects/microservices.yaml")

  depends_on = [helm_release.argocd]
}

# ---------------------------------------------------------------------------
# Root App-of-Apps — ArgoCD will discover and sync everything under argocd/apps/
# ---------------------------------------------------------------------------

resource "kubectl_manifest" "argocd_root_app" {
  yaml_body = templatefile("${path.module}/../argocd/apps/root-app.yaml", {
    repo_url     = var.gitops_repo_url
    repo_revision = var.gitops_repo_revision
  })

  depends_on = [
    kubectl_manifest.argocd_project_infrastructure,
    kubectl_manifest.argocd_project_microservices,
  ]
}
