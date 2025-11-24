#!/bin/bash

# Example Vault CLI commands for setting up develop environment secrets
# Based on Docker Compose configuration requirements

export VAULT_ADDR="https://vault-devops.extosoft.app"
export VAULT_TOKEN="hvs.5CidnJH4HHpfQJz0e49alov8"

echo "🔐 Setting up complete secrets for test-devops-develop environment..."

# Set all the secrets matching Docker Compose environment variables
vault kv put secret/k8s/test-devops-develop \
  DD_API_KEY="hvs.5CidnJH4HHpfQJz0e49alov8" \
  DD_SITE="datadoghq.com" \
  DD_ENV="develop" \
  DD_HOSTNAME="test-devops-develop" \
  APP_NAME="test-devops-develop" \
  NODE_ENV="develop" \
  SERVICE_NAME="test-devops" \
  PORT="3000" \
  ENABLE_METRICS="true"

echo "✅ All secrets set successfully!"
echo ""
echo "📋 Verification commands:"
echo "vault kv get secret/k8s/test-devops-develop"
echo ""
echo "🔍 Check specific fields:"
echo "vault kv get -field=DD_API_KEY secret/k8s/test-devops-develop"
echo "vault kv get -field=DD_ENV secret/k8s/test-devops-develop"
echo "vault kv get -field=DD_HOSTNAME secret/k8s/test-devops-develop"
echo "vault kv get -field=NODE_ENV secret/k8s/test-devops-develop"
echo "vault kv get -field=SERVICE_NAME secret/k8s/test-devops-develop"