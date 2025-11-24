#!/bin/bash
# Cloudflare Origin Certificate Setup Script

NAMESPACE="gke-nonprod-test-devops-develop"
SECRET_NAME="test-devops-dev-tls"
CERT_FILE="origin-cert.pem"
KEY_FILE="origin-key.pem"

echo "🔐 Creating Cloudflare Origin Certificate for test-devops-dev..."

# Check if certificate files exist
if [[ ! -f "$CERT_FILE" || ! -f "$KEY_FILE" ]]; then
    echo "❌ Certificate files not found!"
    echo "Please download from Cloudflare Dashboard:"
    echo "   SSL/TLS → Origin Server → Create Certificate"
    echo "   Save as: $CERT_FILE and $KEY_FILE"
    exit 1
fi

# Delete existing secret if exists
kubectl delete secret $SECRET_NAME -n $NAMESPACE 2>/dev/null || true

# Create new TLS secret
kubectl create secret tls $SECRET_NAME \
    --cert=$CERT_FILE \
    --key=$KEY_FILE \
    -n $NAMESPACE

if [ $? -eq 0 ]; then
    echo "✅ TLS Secret created successfully!"
    echo "🔍 Verifying secret:"
    kubectl get secret $SECRET_NAME -n $NAMESPACE -o jsonpath='{.data}' | jq 'keys'
else
    echo "❌ Failed to create TLS secret"
    exit 1
fi

echo ""
echo "🚀 Next Steps:"
echo "1. Update DNS: test-devops-dev.extosoft.app → 35.240.213.142"
echo "2. Set Cloudflare SSL mode to 'Full (strict)'"
echo "3. Deploy Helm chart: helm upgrade test-devops-develop ."