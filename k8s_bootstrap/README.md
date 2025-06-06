# Create [K3d](https://k3d.io/v5.5.1/) cluster

```bash
k3d cluster create --config k3d_config.yaml
```

# Install [ArgoCD](https://argo-cd.readthedocs.io/en/stable/) as GitOps Engine

### Prerequisites: need to have Helm installed

```bash
# Add Argo Repo
helm repo add argo https://argoproj.github.io/argo-helm

# Install ArgoCD using Helm
helm upgrade --create-namespace --install --namespace argocd argocd argo/argo-cd -f argocd/values.yaml

### 