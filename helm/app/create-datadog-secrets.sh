#!/bin/bash

# Script to create Datadog API Key secret for each environment
# Usage: ./create-datadog-secrets.sh <DATADOG_API_KEY>

if [ -z "$1" ]; then
  echo "Usage: $0 <DATADOG_API_KEY>"
  echo "Example: $0 1234567890abcdef"
  exit 1
fi

DATADOG_API_KEY=$1

echo "Creating Datadog API Key secrets for all environments..."

# Development
echo "Creating secret for develop environment..."
kubectl create secret generic datadog-api-key \
  --from-literal=api-key=$DATADOG_API_KEY \
  --namespace=test-devops-develop \
  --dry-run=client -o yaml | kubectl apply -f -

# UAT
echo "Creating secret for UAT environment..."
kubectl create secret generic datadog-api-key \
  --from-literal=api-key=$DATADOG_API_KEY \
  --namespace=test-devops-uat \
  --dry-run=client -o yaml | kubectl apply -f -

# Production
echo "Creating secret for production environment..."
kubectl create secret generic datadog-api-key \
  --from-literal=api-key=$DATADOG_API_KEY \
  --namespace=test-devops-prod \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Datadog API Key secrets created successfully!"
echo ""
echo "You can now install the Helm chart without --set datadog.apiKey flag"
echo "The secret will be automatically mounted by the Datadog Agent pods"

