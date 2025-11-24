#!/bin/bash

# Vault Secrets Creation Script for test-devops
# Created: $(date)
# Usage: ./create-vault-secrets.sh

set -euo pipefail

# Vault configuration
export VAULT_ADDR=https://vault-devops.extosoft.app
export VAULT_TOKEN=hvs.5CidnJH4HHpfQJz0e49alov8

echo "🔐 Creating Vault Secrets for test-devops environments"
echo "====================================================="

# Development Environment
echo "📝 Creating Development Secret..."
vault kv put secret/k8s/test-devops-develop \
  PORT="3000" \
  NODE_ENV="develop" \
  ENABLE_METRICS="true" \
  SERVICE_NAME="test-devops" \
  DD_DOGSTATSD_PORT="8125" \
  DD_AGENT_HOST="datadog-agent.datadog.svc.cluster.local"

# UAT Environment  
echo "📝 Creating UAT Secret..."
vault kv put secret/k8s/test-devops-uat \
  PORT="3000" \
  NODE_ENV="uat" \
  ENABLE_METRICS="true" \
  SERVICE_NAME="test-devops" \
  DD_DOGSTATSD_PORT="8125" \
  DD_AGENT_HOST="datadog-agent.datadog.svc.cluster.local"

# Production Environment
echo "📝 Creating Production Secret..."
vault kv put secret/k8s/test-devops-production \
  PORT="3000" \
  NODE_ENV="production" \
  ENABLE_METRICS="true" \
  SERVICE_NAME="test-devops" \
  DD_DOGSTATSD_PORT="8125" \
  DD_AGENT_HOST="datadog-agent.datadog.svc.cluster.local"

echo ""
echo "✅ All Vault secrets created successfully!"
echo ""
echo "📊 Secret Paths:"
echo "- Development: secret/data/k8s/test-devops-develop"
echo "- UAT: secret/data/k8s/test-devops-uat"  
echo "- Production: secret/data/k8s/test-devops-production"
echo ""
echo "🔑 Environment Variables Available:"
echo "- PORT: Application port"
echo "- NODE_ENV: Node.js environment"
echo "- ENABLE_METRICS: Datadog metrics flag"
echo "- SERVICE_NAME: Application service name"
echo "- DD_DOGSTATSD_PORT: StatsD port"
echo "- DD_AGENT_HOST: External Datadog agent host"