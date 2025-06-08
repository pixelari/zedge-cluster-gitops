### 
# 🐾 Zedge Farm GitOps Kubernetes Environment

This project sets up a fully automated, GitOps-driven Kubernetes environment using [k3d](https://k3d.io/), [ArgoCD](https://argo-cd.readthedocs.io/), [Argo Rollouts](https://argoproj.github.io/argo-rollouts/), [Emissary Ingress](https://www.getambassador.io/docs/emissary/), [cert-manager](https://cert-manager.io/), and [Prometheus stack](https://github.com/prometheus-community/helm-charts).

> ✅ Tested on macOS Sequoia 15.5

---

## 🚀 Quickstart

```bash
make yolo
```

This will:
1. Create a `k3d` cluster using `bootstrap/k3d_config.yaml`
2. Update local `/etc/hosts` file with required DNS entries and ports (Optional)
3. Install ArgoCD via Helm
4. Bootstrap GitOps with Apps-of-Apps pattern

---

## 🌳 Repository Structure

```text
.
├── apps-of-apps              # ArgoCD App of Apps Helm chart
├── bootstrap                 # Cluster config and bootstrap values
├── zedge-gitops              # Core GitOps repo with infra & apps
│   ├── infrastructure        # Helm charts for Prometheus, Emissary, etc.
│   │   ├── argo-rollouts
│   │   ├── cert-manager
│   │   ├── emissary
│   │   └── prometheus
│   └── applications          # Animal apps: cats, dogs, horses
│       ├── Chart.yaml
│       ├── templates
│       ├── values-cats.yaml
│       ├── values-dogs.yaml
│       ├── values-horses.yaml
│       └── values.yaml
├── Makefile                  # Automated setup commands
├── README.md
└── LICENSE
```

---

## 🛠️ Prerequisites

- [k3d](https://k3d.io/v5.5.1/)
- [Helm v3](https://helm.sh/)
- [kubectl](https://kubernetes.io/docs/reference/kubectl/)
- [make](https://www.gnu.org/software/make/)

---

## 🔐 GitHub Access

1. Go to [GitHub PAT Settings](https://github.com/settings/tokens)
2. Generate a **classic token** with:
   - `repo` scope (for private repos)
3. Add the token to the `Makefile` or inject via:
   ```bash
   export GITHUB_PAT=ghp_xxx
   ```

---

## 🌐 Hostnames & URLs

After `make yolo`, access services using:

| Service       | URL                        |
|---------------|----------------------------|
| Cats App      | http://cats.farm:8080      |
| Dogs App      | http://dogs.farm:8080      |
| Horses App    | http://horses.farm:8080    |
| ArgoCD        | http://argocd.farm:8080    |
| Grafana       | http://grafna.farm:8080    |
| Prometheus    | http://prom.farm:8080      |
| Argo Rollouts | http://rollouts.farm:8080  |
| AlertManager  | http://alerts.farm:8080    |


> 🔒 Note: Applications can also be accessed via self-signed TLS endpoints (managed by cert-manager) on port `8443`, such as [https://cats.farm:8443](https://cats.farm:8443). This demonstrates the cert-manager certificate issuance flow.

Note: the Makefile updates `/etc/hosts` accordingly.

---

## 🔄 CI/CD Flow

### Build Process
Each application (cats, dogs, horses) has its own Helm values file. Docker images are built separately (externally or CI) and versions updated via Git.

### Application Pipelines

Each service (e.g., cats, dogs, horses) follows a dedicated CI pipeline that:

1. Builds the Docker image:  
   `docker build -t registry/image-name:$TAG .`
2. Pushes it to the container registry:  
   `docker push registry/image-name:$TAG`
3. Updates the corresponding Helm values file (e.g., `values-cats.yaml`) by setting the new `image.tag`
4. Commits and pushes the change to GitHub

ArgoCD detects the change in Git and synchronizes the application.
Argo Rollouts manages progressive delivery (e.g., canary or blue/green rollout strategy).

> ℹ️ All app pipelines are re-usable and parameterized to work with multiple services by passing in the app name, Dockerfile path, Helm values file, etc.

### GitOps Delivery
- Git commit triggers ArgoCD sync
- Argo Rollouts handles progressive delivery (canary, blue/green)
- Helm used for templating and values injection

### Rollback
- Argo Rollouts enables manual or automated rollback based on pod health and step status
- Rollbacks do not modify Git history

### GitOps Bootstrap Pipeline

The `apps-of-apps-ci.yaml` GitHub Actions workflow handles the CI pipeline for deploying the `apps-of-apps` Helm chart which bootstraps the entire GitOps structure.

This pipeline performs the following steps:
1. Installs Helm and the `helm-diff` plugin (on PRs)
2. Runs `helm diff` on pull requests to show the changes
3. Deploys the `apps-of-apps` Helm chart on push to `main` or `dev`:
   ```bash
   helm upgrade --install zedge-gitops . \
     ${{ env.VALUES_FILE_ARGS }} \
     --atomic \
     --wait \
     --timeout ${{ env.TIMEOUT }}
   ```

> 🛠 This pipeline is triggered via GitHub Actions and is also used when running `make install-gitops`.

---

## 📊 Observability

Prometheus + AlertManager + Grafana stack installed:
- Default dashboards loaded
- Alerts (e.g., pod restarts) preconfigured
- Webhook support (e.g., Test endpoints)

---

## 📁 Makefile Commands

| Command                | Description                                |
|------------------------|--------------------------------------------|
| `make yolo`            | Full environment bootstrap                 |
| `make create-cluster`  | Create the k3d cluster                     |
| `make destroy-cluster` | Delete the cluster                         |
| `make install-argo`    | Install ArgoCD and get admin credentials   |
> ℹ️ In a cloud-based production setup, this step would typically be executed by a CI pipeline during the cluster provisioning phase.
| `make install-gitops`  | Bootstrap apps via GitOps                  |
| `make update-hosts`    | Add hosts to /etc/hosts, needs `sudo`      |

---

## 📎 Notes

- Rollouts controlled per app via Helm values (`rollout.enabled`)
- Preview services are created for blue/green and canary deployment
- Canary steps are configurable
- Preview Mappings created conditionally for Emissary