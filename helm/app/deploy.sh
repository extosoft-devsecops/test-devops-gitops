#!/bin/bash

# Deploy script for all environments
# Usage: ./deploy.sh <environment> [image-tag] [datadog-api-key]
# Example: ./deploy.sh develop latest abc123def456

set -e

ENVIRONMENT=$1
IMAGE_TAG=${2:-"latest"}
DATADOG_API_KEY=$3

if [ -z "$ENVIRONMENT" ]; then
  echo "Usage: $0 <environment> [image-tag] [datadog-api-key]"
  echo ""
  echo "Environments:"
  echo "  - develop"
  echo "  - uat"
  echo "  - prod-gke"
  echo "  - prod-eks"
  echo ""
  echo "Example: $0 develop v1.0.0 abc123"
  exit 1
fi

# Set namespace based on environment
case $ENVIRONMENT in
  develop)
    NAMESPACE="test-devops-develop"
    VALUES_FILE="values-develop.yaml"
    ;;
  uat)
    NAMESPACE="test-devops-uat"
    VALUES_FILE="values-uat.yaml"
    ;;
  prod-gke|prod-eks)
    NAMESPACE="test-devops-prod"
    VALUES_FILE="values-${ENVIRONMENT}.yaml"
    ;;
  *)
    echo "❌ Unknown environment: $ENVIRONMENT"
    echo "Valid environments: develop, uat, prod-gke, prod-eks"
    exit 1
    ;;
esac

echo "🚀 Deploying to $ENVIRONMENT environment..."
echo "   Namespace: $NAMESPACE"
echo "   Image Tag: $IMAGE_TAG"
echo "   Values File: $VALUES_FILE"
echo ""

# Create namespace if not exists
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Build helm command
HELM_CMD="helm upgrade --install test-devops . \
  -f $VALUES_FILE \
  --set image.tag=$IMAGE_TAG \
  --namespace $NAMESPACE \
  --wait \
  --timeout 5m"

# Add Datadog API key if provided
if [ -n "$DATADOG_API_KEY" ]; then
  HELM_CMD="$HELM_CMD --set datadog.apiKey=$DATADOG_API_KEY"
  echo "   Datadog API Key: ****** (provided)"
else
  echo "   Datadog API Key: Using existing secret or values file"
fi

echo ""
echo "Executing: $HELM_CMD"
echo ""

# Execute deployment
eval $HELM_CMD

echo ""
echo "✅ Deployment completed successfully!"
echo ""
echo "Check status:"
echo "  kubectl get pods -n $NAMESPACE"
echo ""
echo "View logs:"
echo "  kubectl logs -n $NAMESPACE -l app=test-devops-app --tail=50"
echo ""
echo "Port forward:"
echo "  kubectl port-forward -n $NAMESPACE svc/test-devops-app-test-devops-app 3000:3000"

