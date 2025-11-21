#!/bin/bash

# ===================================================================
# ตรวจสอบ ArgoCD Application Configuration
# ===================================================================

set -e

echo "🔍 Validating ArgoCD Application Manifests..."
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ===================================================================
# ฟังก์ชันตรวจสอบ
# ===================================================================

validate_yaml() {
    local file=$1
    echo -n "  Validating YAML syntax: $(basename $file)... "

    if kubectl apply --dry-run=client -f "$file" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        return 0
    else
        echo -e "${RED}✗${NC}"
        kubectl apply --dry-run=client -f "$file"
        return 1
    fi
}

check_helm_values() {
    local env=$1
    local values_file="../../../../../helms/test-devops/values-${env}.yaml"

    echo -n "  Checking Helm values file: values-${env}.yaml... "

    if [ -f "$values_file" ]; then
        echo -e "${GREEN}✓${NC}"
        return 0
    else
        echo -e "${RED}✗${NC} (file not found: $values_file)"
        return 1
    fi
}

helm_template_test() {
    local env=$1
    local values_file="../../../../../helms/test-devops/values-${env}.yaml"

    echo "  Testing Helm template rendering for ${env}..."

    if helm template test-devops ../../../../../helms/test-devops \
        -f "$values_file" \
        --debug > /tmp/helm-${env}.yaml 2>&1; then
        echo -e "    ${GREEN}✓${NC} Template rendered successfully"
        echo "    Output saved to: /tmp/helm-${env}.yaml"
        return 0
    else
        echo -e "    ${RED}✗${NC} Template rendering failed"
        cat /tmp/helm-${env}.yaml
        return 1
    fi
}

# ===================================================================
# Main Validation
# ===================================================================

echo "📋 Checking prerequisites..."
echo ""

# ตรวจสอบ kubectl
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}✗${NC} kubectl not found. Please install kubectl first."
    exit 1
fi
echo -e "${GREEN}✓${NC} kubectl is installed"

# ตรวจสอบ helm
if ! command -v helm &> /dev/null; then
    echo -e "${RED}✗${NC} helm not found. Please install helm first."
    exit 1
fi
echo -e "${GREEN}✓${NC} helm is installed"

echo ""
echo "================================"
echo "Testing Development Environment"
echo "================================"
validate_yaml "develop/test-devops-develop.yaml"
check_helm_values "develop"
helm_template_test "develop"

#echo ""
#echo "========================"
#echo "Testing UAT Environment"
#echo "========================"
##validate_yaml "uat/test-devops-uat.yaml"
##check_helm_values "uat"
##helm_template_test "uat"

#echo ""
#echo "================================"
#echo "Testing Production (GKE)"
#echo "================================"
#validate_yaml "prod/test-devops-prod-gke.yaml"
#check_helm_values "prod-gke"
#helm_template_test "prod-gke"

#echo ""
#echo "================================"
#echo "Testing Production (EKS)"
#echo "================================"
#validate_yaml "prod/test-devops-prod-eks.yaml"
#check_helm_values "prod-eks"
#helm_template_test "prod-eks"

echo ""
echo "================================"
echo "Validation Summary"
echo "================================"
echo ""
echo -e "${GREEN}✅ All validations passed!${NC}"
echo ""
echo "📝 Next steps:"
echo "  1. Apply to ArgoCD:"
echo "     kubectl apply -f develop/test-devops-develop.yaml"
echo ""
echo "  2. Check application status:"
echo "     argocd app get test-devops-develop"
echo ""
echo "  3. View rendered manifests:"
echo "     cat /tmp/helm-develop.yaml"
echo ""

