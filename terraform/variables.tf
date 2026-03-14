variable "cluster_name" {
  description = "Name of the kind Kubernetes cluster"
  type        = string
  default     = "gitops-demo"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the kind cluster (kind node image tag)"
  type        = string
  default     = "v1.29.2"
}

variable "argocd_namespace" {
  description = "Namespace ArgoCD will be installed into"
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "Helm chart version for ArgoCD"
  type        = string
  default     = "7.3.11"
}

variable "gitops_repo_url" {
  description = "URL of this git repository (used by ArgoCD Applications)"
  type        = string
  default     = "https://github.com/raunoproekspert/kubernetes-terraform-cluster-demo.git"
}

variable "gitops_repo_revision" {
  description = "Git branch/tag/commit ArgoCD will track"
  type        = string
  default     = "main"
}
