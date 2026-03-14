output "cluster_name" {
  description = "Name of the kind cluster"
  value       = kind_cluster.this.name
}

output "cluster_endpoint" {
  description = "API server endpoint"
  value       = kind_cluster.this.endpoint
}

output "kubeconfig_path" {
  description = "Path to the kubeconfig written by kind"
  value       = kind_cluster.this.kubeconfig_path
}

output "argocd_namespace" {
  description = "Namespace where ArgoCD is installed"
  value       = var.argocd_namespace
}

output "argocd_initial_password_command" {
  description = "Command to retrieve the initial ArgoCD admin password"
  value       = "kubectl -n ${var.argocd_namespace} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}

output "argocd_port_forward_command" {
  description = "Command to expose the ArgoCD UI locally"
  value       = "kubectl port-forward svc/argocd-server -n ${var.argocd_namespace} 8080:443"
}
