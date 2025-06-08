.PHONY: update-hosts create-cluster destroy-cluster install-argo install-gitops open-hosts

update-hosts:
	cat ./bootstrap/hosts | sudo tee -a /etc/hosts > /dev/null

create-cluster:
	k3d cluster create --config ./bootstrap/k3d_config.yaml

destroy-cluster:
	k3d cluster delete farm

install-argo:
	helm repo add argo https://argoproj.github.io/argo-helm
	helm repo update
	helm upgrade --install --create-namespace --namespace argocd argocd argo/argo-cd -f ./bootstrap/argocd-values.yaml
	kubectl -n argocd wait --for=condition=Ready pods -l app.kubernetes.io/name=argocd-server --timeout=120s
	@echo "Argo UI credentials:"
	@echo "  Username: admin"
	@echo "  Password: " && kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo

install-gitops:
	cd apps-of-apps && helm upgrade --install farm-gitops . -f values.yaml --set repoPAT=$$GITHUB_PAT

yolo: create-cluster install-argo install-gitops
	@echo "All setup steps completed."