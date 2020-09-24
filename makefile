#!make
SHELL = /bin/bash -o pipefail

export SESSION_SECRET := $(shell openssl rand -base64 32)

.DEFAULT_GOAL := kctl-dry-run

all: kctl-dry-run


kctl-dry-run:
	kubectl apply --dry-run=server -f ./k8s/gcp/deploy-search-app.yaml -o yaml --validate=true

kctl-deployment:
	kubectl apply -f ./k8s/gcp/deploy-search-app.yaml
	@echo
	@kubectl rollout status deployment/search-app --watch=true
	@echo
	@kubectl get pod,svc

kctl-delete:
	@kubectl delete -f ./k8s/gcp/deploy-search-app.yaml
	@echo
	watch kubectl get pod,svc

kctl-logs:
	@kubectl logs --tail=20 -f deployment/search-app --container search-app

kctl-rollout:
	@kubectl rollout status deployment/search-app
#	@kubectl rollout restart deployment/search-app
#	@kubectl exec -it pod/search-app-644654fddb-nsl9h -- env


kctl-secret-get:
	kubectl get secrets/search-app -o json
#	kubectl get secrets/okteto-secrets -o json | jq -r .data[\"SEARCH_WEB_SESSION_SECRET\"] | base64 -d; echo

kctl-secret-create:
	kubectl create secret generic search-app --from-literal=session_secret=${SESSION_SECRET}

kctl-port-forward-search-app:
	set -e ; \
	POD=$$(kubectl get pod --selector="app=search-app" --output jsonpath='{.items[0].metadata.name}') ; \
	echo "===> kubectl port-forward $${POD} 8080:8080" ; \
	kubectl port-forward $${POD} 8080:8080

kctl-port-forward-argocd:
	@kubectl port-forward svc/argocd-server -n argocd 8080:443

ping:
	curl -k -H "X-Probe: LivenessProbe" https://0.0.0.0:4200/ping; echo
