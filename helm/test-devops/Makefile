# Test-DevOps Helm Chart Makefile

# Variables
CHART_NAME := test-devops
APP_NAME := test-app
NAMESPACE := default

# Environments
DEV_VALUES := values-dev.yaml
UAT_VALUES := values-uat.yaml
PROD_VALUES := values-prod.yaml

.PHONY: help lint template install-dev install-uat install-prod uninstall status logs test

help: ## Show this help
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

lint: ## Lint the Helm chart
	@echo "🔍 Linting Helm chart..."
	helm lint .

template: ## Template all environments
	@echo "📝 Templating dev environment..."
	helm template $(APP_NAME) . --values $(DEV_VALUES) --output-dir /tmp/helm-dev
	@echo "📝 Templating UAT environment..."
	helm template $(APP_NAME) . --values $(UAT_VALUES) --output-dir /tmp/helm-uat
	@echo "📝 Templating production environment..."
	helm template $(APP_NAME) . --values $(PROD_VALUES) --output-dir /tmp/helm-prod
	@echo "✅ Templates generated in /tmp/helm-*"

template-dev: ## Template development environment only
	helm template $(APP_NAME) . --values $(DEV_VALUES)

template-uat: ## Template UAT environment only
	helm template $(APP_NAME) . --values $(UAT_VALUES)

template-prod: ## Template production environment only
	helm template $(APP_NAME) . --values $(PROD_VALUES)

dry-run-dev: ## Dry run development deployment
	@echo "🧪 Dry run: Development deployment..."
	helm install $(APP_NAME) . --values $(DEV_VALUES) --dry-run --debug

dry-run-uat: ## Dry run UAT deployment
	@echo "🧪 Dry run: UAT deployment..."
	helm install $(APP_NAME) . --values $(UAT_VALUES) --dry-run --debug

dry-run-prod: ## Dry run production deployment
	@echo "🧪 Dry run: Production deployment..."
	helm install $(APP_NAME) . --values $(PROD_VALUES) --dry-run --debug

install-dev: ## Install development environment
	@echo "🚀 Installing development environment..."
	helm upgrade --install $(APP_NAME) . \
		--values $(DEV_VALUES) \
		--namespace $(NAMESPACE) \
		--create-namespace \
		--wait --timeout=300s

install-uat: ## Install UAT environment
	@echo "🚀 Installing UAT environment..."
	helm upgrade --install $(APP_NAME) . \
		--values $(UAT_VALUES) \
		--namespace uat \
		--create-namespace \
		--wait --timeout=300s

install-prod: ## Install production environment
	@echo "🚀 Installing production environment..."
	helm upgrade --install $(APP_NAME) . \
		--values $(PROD_VALUES) \
		--namespace production \
		--create-namespace \
		--wait --timeout=300s

install-dev-no-vault: ## Install dev without Vault (local testing)
	@echo "🚀 Installing development (no Vault)..."
	helm upgrade --install $(APP_NAME) . \
		--values $(DEV_VALUES) \
		--set vault.enabled=false \
		--namespace $(NAMESPACE) \
		--create-namespace \
		--wait --timeout=300s

uninstall: ## Uninstall from default namespace
	@echo "🗑️ Uninstalling from default namespace..."
	helm uninstall $(APP_NAME) --namespace $(NAMESPACE) || true

uninstall-uat: ## Uninstall from UAT namespace
	@echo "🗑️ Uninstalling from UAT namespace..."
	helm uninstall $(APP_NAME) --namespace uat || true

uninstall-prod: ## Uninstall from production namespace
	@echo "🗑️ Uninstalling from production namespace..."
	helm uninstall $(APP_NAME) --namespace production || true

status: ## Show Helm release status
	@echo "📊 Checking release status..."
	helm status $(APP_NAME) --namespace $(NAMESPACE) 2>/dev/null || echo "No release in default namespace"
	helm status $(APP_NAME) --namespace uat 2>/dev/null || echo "No release in UAT namespace"
	helm status $(APP_NAME) --namespace production 2>/dev/null || echo "No release in production namespace"

logs: ## Show application logs
	@echo "📝 Application logs (default namespace)..."
	kubectl logs -f deployment/$(APP_NAME)-$(CHART_NAME) --namespace $(NAMESPACE) 2>/dev/null || echo "No deployment in default namespace"

logs-uat: ## Show UAT application logs
	@echo "📝 Application logs (UAT namespace)..."
	kubectl logs -f deployment/$(APP_NAME)-$(CHART_NAME) --namespace uat

logs-prod: ## Show production application logs
	@echo "📝 Application logs (production namespace)..."
	kubectl logs -f deployment/$(APP_NAME)-$(CHART_NAME) --namespace production

test: ## Run basic connectivity tests
	@echo "🧪 Testing application connectivity..."
	kubectl get pods -l app.kubernetes.io/name=$(CHART_NAME) --namespace $(NAMESPACE)
	@echo "Testing service endpoints..."
	kubectl get svc -l app.kubernetes.io/name=$(CHART_NAME) --namespace $(NAMESPACE)
	@echo "Testing secret provider class..."
	kubectl get secretproviderclass vault-secrets --namespace $(NAMESPACE) 2>/dev/null || echo "No SecretProviderClass found"

test-vault: ## Test Vault secret injection
	@echo "🔐 Testing Vault secret injection..."
	kubectl describe secretproviderclass vault-secrets --namespace $(NAMESPACE)
	@echo "Checking pod events for Vault CSI..."
	kubectl get events --field-selector reason=SecretProviderClassPodStatus --namespace $(NAMESPACE)

test-datadog: ## Test external Datadog connectivity
	@echo "📊 Testing external Datadog connectivity..."
	kubectl exec -it deployment/$(APP_NAME)-$(CHART_NAME) --namespace $(NAMESPACE) -- \
		nc -zv datadog-agent.datadog.svc.cluster.local 8125 || echo "Cannot connect to external Datadog agent"

upgrade-dev: ## Upgrade development environment
	@echo "⬆️ Upgrading development environment..."
	helm upgrade $(APP_NAME) . --values $(DEV_VALUES) --namespace $(NAMESPACE)

upgrade-uat: ## Upgrade UAT environment
	@echo "⬆️ Upgrading UAT environment..."
	helm upgrade $(APP_NAME) . --values $(UAT_VALUES) --namespace uat

upgrade-prod: ## Upgrade production environment
	@echo "⬆️ Upgrading production environment..."
	helm upgrade $(APP_NAME) . --values $(PROD_VALUES) --namespace production

rollback: ## Rollback to previous release
	@echo "↩️ Rolling back to previous release..."
	helm rollback $(APP_NAME) --namespace $(NAMESPACE)

history: ## Show release history
	@echo "📜 Release history..."
	helm history $(APP_NAME) --namespace $(NAMESPACE) 2>/dev/null || echo "No history in default namespace"

package: ## Package the Helm chart
	@echo "📦 Packaging Helm chart..."
	helm package .

clean: ## Clean temporary files
	@echo "🧹 Cleaning temporary files..."
	rm -rf /tmp/helm-*
	rm -f *.tgz

verify-prerequisites: ## Verify Kubernetes prerequisites
	@echo "✅ Verifying prerequisites..."
	@echo "Checking CSI driver..."
	kubectl get pods -n kube-system -l app=secrets-store-csi-driver || echo "❌ CSI driver not found"
	@echo "Checking Vault CSI provider..."
	kubectl get pods -n kube-system -l app.kubernetes.io/name=vault-csi-provider || echo "❌ Vault CSI provider not found"
	@echo "Checking external Datadog agent..."
	kubectl get svc -n datadog datadog-agent || echo "❌ External Datadog agent not found"

# GitOps targets
argocd-app: ## Generate ArgoCD application manifest
	@echo "🔄 Generating ArgoCD application..."
	@cat > argocd-application.yaml << 'EOF'
	apiVersion: argoproj.io/v1alpha1
	kind: Application
	metadata:
	  name: test-devops-app
	  namespace: argocd
	spec:
	  project: default
	  source:
	    repoURL: https://github.com/your-org/test-devops-gitops
	    targetRevision: HEAD
	    path: helm/test-devops
	    helm:
	      valueFiles:
	      - values-prod.yaml
	  destination:
	    server: https://kubernetes.default.svc
	    namespace: production
	  syncPolicy:
	    automated:
	      prune: true
	      selfHeal: true
	EOF
	@echo "✅ ArgoCD application manifest created: argocd-application.yaml"

install-dependencies: verify-prerequisites ## Install all required dependencies
	@echo "🔧 Installing Helm chart dependencies..."
	helm dependency update

all: lint template dry-run-dev ## Run full validation pipeline
	@echo "✅ Full validation completed!"