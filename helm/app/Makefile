# Helm Chart Makefile for Test DevOps

CHART_NAME := test-devops
CHART_DIR := .
NAMESPACE_PREFIX := test-devops

# Default values
IMAGE_TAG ?= latest
DATADOG_API_KEY ?=

.PHONY: help
help: ## Show this help message
	@echo "Usage: make [target]"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'

.PHONY: lint
lint: ## Lint the Helm chart
	@echo "🔍 Linting Helm chart..."
	helm lint $(CHART_DIR)

.PHONY: template-local
template-local: ## Generate templates for local environment
	@echo "📄 Generating templates for local environment..."
	helm template $(CHART_NAME)-local $(CHART_DIR) -f values-local.yaml

.PHONY: template-develop
template-develop: ## Generate templates for develop environment
	@echo "📄 Generating templates for develop environment..."
	helm template $(CHART_NAME) $(CHART_DIR) -f values-develop.yaml

.PHONY: template-uat
template-uat: ## Generate templates for UAT environment
	@echo "📄 Generating templates for UAT environment..."
	helm template $(CHART_NAME) $(CHART_DIR) -f values-uat.yaml

.PHONY: template-prod-gke
template-prod-gke: ## Generate templates for prod-gke environment
	@echo "📄 Generating templates for prod-gke environment..."
	helm template $(CHART_NAME) $(CHART_DIR) -f values-prod-gke.yaml

.PHONY: template-prod-eks
template-prod-eks: ## Generate templates for prod-eks environment
	@echo "📄 Generating templates for prod-eks environment..."
	helm template $(CHART_NAME) $(CHART_DIR) -f values-prod-eks.yaml

.PHONY: dry-run-develop
dry-run-develop: ## Dry run for develop environment
	@echo "🧪 Dry run for develop environment..."
	helm install $(CHART_NAME) $(CHART_DIR) \
		-f values-develop.yaml \
		--namespace $(NAMESPACE_PREFIX)-develop \
		--dry-run --debug

.PHONY: dry-run-uat
dry-run-uat: ## Dry run for UAT environment
	@echo "🧪 Dry run for UAT environment..."
	helm install $(CHART_NAME) $(CHART_DIR) \
		-f values-uat.yaml \
		--namespace $(NAMESPACE_PREFIX)-uat \
		--dry-run --debug

.PHONY: dry-run-prod-gke
dry-run-prod-gke: ## Dry run for prod-gke environment
	@echo "🧪 Dry run for prod-gke environment..."
	helm install $(CHART_NAME) $(CHART_DIR) \
		-f values-prod-gke.yaml \
		--namespace $(NAMESPACE_PREFIX)-prod \
		--dry-run --debug

.PHONY: dry-run-prod-eks
dry-run-prod-eks: ## Dry run for prod-eks environment
	@echo "🧪 Dry run for prod-eks environment..."
	helm install $(CHART_NAME) $(CHART_DIR) \
		-f values-prod-eks.yaml \
		--namespace $(NAMESPACE_PREFIX)-prod \
		--dry-run --debug

.PHONY: install-develop
install-develop: ## Install to develop environment
	@if [ -z "$(DATADOG_API_KEY)" ]; then \
		echo "⚠️  Warning: DATADOG_API_KEY not set"; \
		echo "Usage: make install-develop DATADOG_API_KEY=your-key IMAGE_TAG=v1.0.0"; \
		exit 1; \
	fi
	@echo "🚀 Installing to develop environment..."
	kubectl create namespace $(NAMESPACE_PREFIX)-develop --dry-run=client -o yaml | kubectl apply -f -
	helm upgrade --install $(CHART_NAME) $(CHART_DIR) \
		-f values-develop.yaml \
		--set image.tag=$(IMAGE_TAG) \
		--set datadog.apiKey=$(DATADOG_API_KEY) \
		--namespace $(NAMESPACE_PREFIX)-develop \
		--wait

.PHONY: install-uat
install-uat: ## Install to UAT environment
	@if [ -z "$(DATADOG_API_KEY)" ]; then \
		echo "⚠️  Warning: DATADOG_API_KEY not set"; \
		echo "Usage: make install-uat DATADOG_API_KEY=your-key IMAGE_TAG=v1.0.0"; \
		exit 1; \
	fi
	@echo "🚀 Installing to UAT environment..."
	kubectl create namespace $(NAMESPACE_PREFIX)-uat --dry-run=client -o yaml | kubectl apply -f -
	helm upgrade --install $(CHART_NAME) $(CHART_DIR) \
		-f values-uat.yaml \
		--set image.tag=$(IMAGE_TAG) \
		--set datadog.apiKey=$(DATADOG_API_KEY) \
		--namespace $(NAMESPACE_PREFIX)-uat \
		--wait

.PHONY: install-prod-gke
install-prod-gke: ## Install to prod-gke environment
	@if [ -z "$(DATADOG_API_KEY)" ]; then \
		echo "⚠️  Warning: DATADOG_API_KEY not set"; \
		echo "Usage: make install-prod-gke DATADOG_API_KEY=your-key IMAGE_TAG=v1.0.0"; \
		exit 1; \
	fi
	@echo "🚀 Installing to prod-gke environment..."
	kubectl create namespace $(NAMESPACE_PREFIX)-prod --dry-run=client -o yaml | kubectl apply -f -
	helm upgrade --install $(CHART_NAME) $(CHART_DIR) \
		-f values-prod-gke.yaml \
		--set image.tag=$(IMAGE_TAG) \
		--set datadog.apiKey=$(DATADOG_API_KEY) \
		--namespace $(NAMESPACE_PREFIX)-prod \
		--wait

.PHONY: install-prod-eks
install-prod-eks: ## Install to prod-eks environment
	@if [ -z "$(DATADOG_API_KEY)" ]; then \
		echo "⚠️  Warning: DATADOG_API_KEY not set"; \
		echo "Usage: make install-prod-eks DATADOG_API_KEY=your-key IMAGE_TAG=v1.0.0"; \
		exit 1; \
	fi
	@echo "🚀 Installing to prod-eks environment..."
	kubectl create namespace $(NAMESPACE_PREFIX)-prod --dry-run=client -o yaml | kubectl apply -f -
	helm upgrade --install $(CHART_NAME) $(CHART_DIR) \
		-f values-prod-eks.yaml \
		--set image.tag=$(IMAGE_TAG) \
		--set datadog.apiKey=$(DATADOG_API_KEY) \
		--namespace $(NAMESPACE_PREFIX)-prod \
		--wait

.PHONY: uninstall-develop
uninstall-develop: ## Uninstall from develop environment
	@echo "🗑️  Uninstalling from develop environment..."
	helm uninstall $(CHART_NAME) --namespace $(NAMESPACE_PREFIX)-develop

.PHONY: uninstall-uat
uninstall-uat: ## Uninstall from UAT environment
	@echo "🗑️  Uninstalling from UAT environment..."
	helm uninstall $(CHART_NAME) --namespace $(NAMESPACE_PREFIX)-uat

.PHONY: uninstall-prod-gke
uninstall-prod-gke: ## Uninstall from prod-gke environment
	@echo "🗑️  Uninstalling from prod-gke environment..."
	helm uninstall $(CHART_NAME) --namespace $(NAMESPACE_PREFIX)-prod

.PHONY: uninstall-prod-eks
uninstall-prod-eks: ## Uninstall from prod-eks environment
	@echo "🗑️  Uninstalling from prod-eks environment..."
	helm uninstall $(CHART_NAME) --namespace $(NAMESPACE_PREFIX)-prod

.PHONY: status-develop
status-develop: ## Check status in develop environment
	@echo "📊 Status for develop environment:"
	@helm status $(CHART_NAME) --namespace $(NAMESPACE_PREFIX)-develop || echo "Not installed"
	@echo "\nPods:"
	@kubectl get pods -n $(NAMESPACE_PREFIX)-develop -l app=test-devops-app

.PHONY: status-uat
status-uat: ## Check status in UAT environment
	@echo "📊 Status for UAT environment:"
	@helm status $(CHART_NAME) --namespace $(NAMESPACE_PREFIX)-uat || echo "Not installed"
	@echo "\nPods:"
	@kubectl get pods -n $(NAMESPACE_PREFIX)-uat -l app=test-devops-app

.PHONY: status-prod
status-prod: ## Check status in production environment
	@echo "📊 Status for production environment:"
	@helm status $(CHART_NAME) --namespace $(NAMESPACE_PREFIX)-prod || echo "Not installed"
	@echo "\nPods:"
	@kubectl get pods -n $(NAMESPACE_PREFIX)-prod -l app=test-devops-app

.PHONY: logs-develop
logs-develop: ## View logs for develop environment
	@echo "📋 Logs for develop environment:"
	kubectl logs -n $(NAMESPACE_PREFIX)-develop -l app=test-devops-app --tail=100 -f

.PHONY: logs-uat
logs-uat: ## View logs for UAT environment
	@echo "📋 Logs for UAT environment:"
	kubectl logs -n $(NAMESPACE_PREFIX)-uat -l app=test-devops-app --tail=100 -f

.PHONY: logs-prod
logs-prod: ## View logs for production environment
	@echo "📋 Logs for production environment:"
	kubectl logs -n $(NAMESPACE_PREFIX)-prod -l app=test-devops-app --tail=100 -f

.PHONY: local-setup
local-setup: ## Setup local Kubernetes (interactive helper)
	@./setup-local-k8s.sh

.PHONY: local-start
local-start: ## Start local Kubernetes deployment (Docker Desktop/Minikube)
	@./local-test.sh start

.PHONY: local-stop
local-stop: ## Stop local Kubernetes deployment
	@./local-test.sh stop

.PHONY: local-restart
local-restart: ## Restart local Kubernetes deployment
	@./local-test.sh restart

.PHONY: local-status
local-status: ## Check local deployment status
	@./local-test.sh status

.PHONY: local-logs
local-logs: ## View local deployment logs
	@./local-test.sh logs

.PHONY: local-test
local-test: ## Test local deployment
	@./local-test.sh test

.PHONY: local-cleanup
local-cleanup: ## Cleanup local deployment (removes namespace)
	@./local-test.sh cleanup

.PHONY: package
package: lint ## Package the Helm chart
	@echo "📦 Packaging Helm chart..."
	helm package $(CHART_DIR)

.PHONY: test-all
test-all: lint template-develop template-uat template-prod-gke template-prod-eks ## Run all tests
	@echo "✅ All tests passed!"

