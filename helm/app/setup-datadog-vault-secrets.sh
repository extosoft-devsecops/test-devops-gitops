#!/bin/bash

# Script to setup complete application secrets in Vault for each environment
# Usage: ./setup-datadog-vault-secrets.sh <VAULT_TOKEN> <DATADOG_API_KEY>

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <VAULT_TOKEN> <DATADOG_API_KEY>"
  echo "Example: $0 hvs.XXXXXXX 1234567890abcdef"
  exit 1
fi

VAULT_TOKEN=$1
DATADOG_API_KEY=$2
VAULT_ADDR="https://vault-devops.extosoft.app"

export VAULT_ADDR
export VAULT_TOKEN

echo "🔐 Setting up complete application secrets in Vault..."
echo "Vault Address: $VAULT_ADDR"

# Development Environment
echo "📝 Setting secrets for develop environment..."
vault kv put secret/k8s/test-devops-develop \
  DD_API_KEY="$DATADOG_API_KEY" \
  DD_SITE="datadoghq.com" \
  DD_ENV="develop" \
  DD_HOSTNAME="test-devops-develop" \
  APP_NAME="test-devops-develop" \
  NODE_ENV="develop" \
  SERVICE_NAME="test-devops" \
  PORT="3000" \
  ENABLE_METRICS="true"

if [ $? -eq 0 ]; then
  echo "✅ Develop environment secrets created successfully"
else
  echo "❌ Failed to create develop environment secrets"
fi

# UAT Environment  
echo "📝 Setting secrets for UAT environment..."
vault kv put secret/k8s/test-devops-uat \
  DD_API_KEY="$DATADOG_API_KEY" \
  DD_SITE="datadoghq.com" \
  DD_ENV="uat" \
  DD_HOSTNAME="test-devops-uat" \
  APP_NAME="test-devops-uat" \
  NODE_ENV="uat" \
  SERVICE_NAME="test-devops" \
  PORT="3000" \
  ENABLE_METRICS="true"

if [ $? -eq 0 ]; then
  echo "✅ UAT environment secrets created successfully"
else
  echo "❌ Failed to create UAT environment secrets"
fi

# Production GKE Environment
echo "📝 Setting secrets for production-gke environment..."
vault kv put secret/k8s/test-devops-prod-gke \
  DD_API_KEY="$DATADOG_API_KEY" \
  DD_SITE="datadoghq.com" \
  DD_ENV="production" \
  DD_HOSTNAME="test-devops-prod-gke" \
  APP_NAME="test-devops-prod-gke" \
  NODE_ENV="production" \
  SERVICE_NAME="test-devops" \
  PORT="3000" \
  ENABLE_METRICS="true"

if [ $? -eq 0 ]; then
  echo "✅ Production-GKE environment secrets created successfully"
else
  echo "❌ Failed to create production-GKE environment secrets"
fi

# Production EKS Environment (if needed)
echo "📝 Setting secrets for production-eks environment..."
vault kv put secret/k8s/test-devops-prod-eks \
  DD_API_KEY="$DATADOG_API_KEY" \
  DD_SITE="datadoghq.com" \
  DD_ENV="production" \
  DD_HOSTNAME="test-devops-prod-eks" \
  APP_NAME="test-devops-prod-eks" \
  NODE_ENV="production" \
  SERVICE_NAME="test-devops" \
  PORT="3000" \
  ENABLE_METRICS="true"

if [ $? -eq 0 ]; then
  echo "✅ Production-EKS environment secrets created successfully"
else
  echo "❌ Failed to create production-EKS environment secrets"
fi

echo ""
echo "🎉 All application secrets have been configured in Vault!"
echo ""
echo "📋 Summary of created secrets with complete environment variables:"
echo "  • secret/k8s/test-devops-develop (DD_ENV=develop)"
echo "  • secret/k8s/test-devops-uat (DD_ENV=uat)"  
echo "  • secret/k8s/test-devops-prod-gke (DD_ENV=production)"
echo "  • secret/k8s/test-devops-prod-eks (DD_ENV=production)"
echo ""
echo "🚀 You can now deploy your Helm charts with complete Vault integration!"
echo "   The application and Datadog Agent will automatically retrieve all secrets from Vault."

# Production EKS Environment (if needed)
echo "📝 Setting Datadog API Key for production-eks environment..."
vault kv put secret/k8s/test-devops-prod-eks \
  datadog_api_key="$DATADOG_API_KEY"

if [ $? -eq 0 ]; then
  echo "✅ Production-EKS environment secret created successfully"
else
  echo "❌ Failed to create production-EKS environment secret"
fi

echo ""
echo "🎉 All Datadog API Key secrets have been configured in Vault!"
echo ""
echo "📋 Summary of created secrets:"
echo "  • secret/k8s/test-devops-develop"
echo "  • secret/k8s/test-devops-uat"
echo "  • secret/k8s/test-devops-prod-gke"
echo "  • secret/k8s/test-devops-prod-eks"
echo ""
echo "🚀 You can now deploy your Helm charts with Vault integration enabled!"
echo "   The Datadog Agent will automatically retrieve the API key from Vault."