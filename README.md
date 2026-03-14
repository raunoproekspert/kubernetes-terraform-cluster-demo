# Kubernetes GitOps Demo — Terraform + ArgoCD + Helm

A fully GitOps-driven local Kubernetes cluster. Terraform provisions a `kind` cluster and bootstraps ArgoCD. ArgoCD then manages every subsequent workload through the App-of-Apps pattern.

## Architecture

```
Terraform
    │
    ├─ Provision kind cluster (2 nodes)
    │
    └─ Bootstrap ArgoCD (Helm)
           │
           └─ Root App-of-Apps (argocd/apps/)
                  │
                  ├─ cert-manager        (wave 0)
                  ├─ external-secrets    (wave 0)
                  ├─ traefik             (wave 1)
                  ├─ kube-prometheus-stack (wave 2)
                  └─ microservices       (wave 3)
```

## Repository Structure

```
.
├── terraform/
│   ├── main.tf          # Providers + kind cluster
│   ├── variables.tf     # Configurable inputs
│   ├── outputs.tf       # Useful post-apply outputs
│   └── argocd.tf        # ArgoCD Helm install + root app
├── argocd/
│   ├── projects/
│   │   ├── infrastructure.yaml   # AppProject for infra workloads
│   │   └── microservices.yaml    # AppProject for services
│   └── apps/
│       ├── root-app.yaml         # App-of-Apps root
│       ├── traefik.yaml
│       ├── kube-prometheus-stack.yaml
│       ├── cert-manager.yaml
│       ├── external-secrets.yaml
│       └── microservices.yaml
├── helm/
│   ├── traefik/values.yaml
│   ├── kube-prometheus-stack/values.yaml
│   ├── cert-manager/values.yaml
│   ├── external-secrets/values.yaml
│   └── microservices/
│       ├── Chart.yaml            # Umbrella chart scaffold
│       └── values.yaml
└── README.md
```

## Prerequisites

| Tool | Purpose | Install |
|------|---------|---------|
| Docker | Container runtime for kind | [docs.docker.com](https://docs.docker.com/get-docker/) |
| `kind` | Local Kubernetes clusters | `brew install kind` |
| `terraform` >= 1.6 | Cluster provisioning | `brew install terraform` |
| `kubectl` | Cluster interaction | `brew install kubectl` |
| `helm` | Optional — manual chart inspection | `brew install helm` |

## Quickstart

### 1. Configure your repo URL

Every ArgoCD Application manifest needs to know where this repo lives so it can pull Helm values at sync time. Replace `YOUR_REPO_URL` in all `argocd/apps/*.yaml` files:

```bash
# macOS / BSD sed — adjust for GNU sed if needed
find argocd/apps -name "*.yaml" -exec \
  sed -i '' 's|YOUR_REPO_URL|https://github.com/your-org/kubernetes-terraform-cluster-demo|g' {} +
```

Also update `gitops_repo_url` in `terraform/variables.tf` (or pass it as a `-var`).

### 2. Provision the cluster

```bash
cd terraform
terraform init
terraform apply
```

Terraform will:
1. Create a 2-node `kind` cluster with ports 30080/30443 mapped to localhost
2. Install ArgoCD via Helm into the `argocd` namespace
3. Apply the ArgoCD AppProjects and the root App-of-Apps

### 3. Access ArgoCD

```bash
# Get the initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d && echo

# Open the UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Visit https://localhost:8080 — username: admin
```

### 4. Watch ArgoCD sync everything

ArgoCD will detect the root app and begin syncing all child applications in sync-wave order:

- Wave 0: `cert-manager`, `external-secrets`
- Wave 1: `traefik`
- Wave 2: `kube-prometheus-stack` (Prometheus + Grafana)
- Wave 3: `microservices` (empty scaffold)

### 5. Access Grafana

```bash
kubectl port-forward svc/kube-prometheus-stack-grafana -n monitoring 3000:80
# Visit http://localhost:3000 — username: admin, password: admin
```

### 6. Access Traefik Dashboard

```bash
kubectl port-forward svc/traefik -n traefik 9000:9000
# Visit http://localhost:9000/dashboard/
```

## Teardown

```bash
cd terraform
terraform destroy
```

This deletes the kind cluster and all resources inside it.

## Day-2: Adding a Microservice

1. Add a Helm chart dependency to `helm/microservices/Chart.yaml`
2. Add its values under a matching key in `helm/microservices/values.yaml`
3. Run `helm dependency update helm/microservices`
4. Commit and push — ArgoCD will automatically sync

## Day-2: Switching to a Real Cloud Provider

To move from `kind` to AWS EKS (or another provider):

1. Replace the `tehcyx/kind` provider in `terraform/main.tf` with the relevant cloud provider (e.g. `hashicorp/aws` + `aws_eks_cluster`)
2. Update the `helm`, `kubernetes`, and `kubectl` provider auth blocks to use the cloud provider's kubeconfig
3. Remove the NodePort mappings from `helm/traefik/values.yaml` and set `service.type: LoadBalancer`
4. Wire a real `ClusterSecretStore` backend in `helm/external-secrets/values.yaml`

## Component Versions

| Component | Chart Version |
|-----------|--------------|
| ArgoCD | 7.3.11 |
| Traefik | 27.0.2 |
| kube-prometheus-stack | 61.3.2 |
| cert-manager | v1.15.1 |
| external-secrets | 0.10.2 |
