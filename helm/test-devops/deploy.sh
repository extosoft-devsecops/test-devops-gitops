#!/bin/bash

# Test-DevOps Production Deployment Script
# Usage: ./deploy.sh [environment] [action]
# Environments: dev, uat, prod
# Actions: install, upgrade, uninstall, status, test

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CHART_NAME="test-devops"
APP_NAME="test-app"
DEFAULT_NAMESPACE="default"

# Function to print colored output
print_status() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [environment] [action]"
    echo ""
    echo "Environments:"
    echo "  dev     - Development environment (default namespace)"
    echo "  uat     - UAT environment (uat namespace)"
    echo "  prod    - Production environment (production namespace)"
    echo ""
    echo "Actions:"
    echo "  install   - Install new deployment"
    echo "  upgrade   - Upgrade existing deployment"
    echo "  uninstall - Remove deployment"
    echo "  status    - Check deployment status"
    echo "  test      - Run connectivity tests"
    echo "  template  - Generate templates (dry-run)"
    echo "  logs      - Show application logs"
    echo ""
    echo "Examples:"
    echo "  $0 dev install      # Install development environment"
    echo "  $0 prod upgrade     # Upgrade production environment"
    echo "  $0 uat status       # Check UAT status"
    echo "  $0 dev test         # Run development tests"
}

# Function to get environment configuration
get_env_config() {
    local env=$1
    
    case $env in
        dev)
            echo "values-develop.yaml default"
            ;;
        uat)
            echo "values-uat.yaml uat"
            ;;
        prod)
            echo "values-prod.yaml production"
            ;;
        *)
            print_error "Unknown environment: $env"
            show_usage
            exit 1
            ;;
    esac
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if helm is installed
    if ! command -v helm &> /dev/null; then
        print_error "Helm is not installed"
        exit 1
    fi
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed"
        exit 1
    fi
    
    # Check if we can connect to cluster
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to check if CSI drivers are installed
check_csi_drivers() {
    print_status "Checking CSI drivers..."
    
    # Check Secrets Store CSI Driver
    if ! kubectl get pods -n kube-system -l app=secrets-store-csi-driver --no-headers 2>/dev/null | grep -q Running; then
        print_warning "Secrets Store CSI Driver not found or not running"
        print_status "Install with: helm install csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver --namespace kube-system"
    else
        print_success "Secrets Store CSI Driver is running"
    fi
    
    # Check Vault CSI Provider
    if ! kubectl get pods -n kube-system -l app.kubernetes.io/name=vault-csi-provider --no-headers 2>/dev/null | grep -q Running; then
        print_warning "Vault CSI Provider not found or not running"
        print_status "Install with: helm install vault-csi-provider hashicorp/vault-csi-provider --namespace kube-system"
    else
        print_success "Vault CSI Provider is running"
    fi
}

# Function to lint chart
lint_chart() {
    print_status "Linting Helm chart..."
    if helm lint .; then
        print_success "Helm chart lint passed"
    else
        print_error "Helm chart lint failed"
        exit 1
    fi
}

# Function to install/upgrade deployment
deploy() {
    local env=$1
    local action=$2
    local config_info=$(get_env_config $env)
    local values_file=$(echo $config_info | cut -d' ' -f1)
    local namespace=$(echo $config_info | cut -d' ' -f2)
    
    print_status "Preparing to $action $env environment..."
    print_status "Values file: $values_file"
    print_status "Namespace: $namespace"
    
    # Run pre-deployment checks
    lint_chart
    check_csi_drivers
    
    # Template validation
    print_status "Validating templates..."
    if helm template $APP_NAME . --values $values_file > /dev/null; then
        print_success "Template validation passed"
    else
        print_error "Template validation failed"
        exit 1
    fi
    
    # Deploy
    local helm_cmd
    if [ "$action" = "install" ]; then
        helm_cmd="helm install"
    else
        helm_cmd="helm upgrade --install"
    fi
    
    print_status "Deploying with: $helm_cmd"
    
    if $helm_cmd $APP_NAME . \
        --values $values_file \
        --namespace $namespace \
        --create-namespace \
        --wait \
        --timeout=300s; then
        
        print_success "$env environment deployed successfully!"
        
        # Show deployment status
        echo ""
        print_status "Deployment status:"
        helm status $APP_NAME --namespace $namespace
        
        echo ""
        print_status "Pod status:"
        kubectl get pods -l app.kubernetes.io/name=$CHART_NAME --namespace $namespace
        
    else
        print_error "Deployment failed!"
        exit 1
    fi
}

# Function to uninstall deployment
uninstall() {
    local env=$1
    local config_info=$(get_env_config $env)
    local namespace=$(echo $config_info | cut -d' ' -f2)
    
    print_warning "Uninstalling $env environment from namespace: $namespace"
    read -p "Are you sure? (y/N): " confirm
    
    if [[ $confirm =~ ^[Yy]$ ]]; then
        if helm uninstall $APP_NAME --namespace $namespace; then
            print_success "$env environment uninstalled successfully!"
        else
            print_error "Uninstall failed!"
            exit 1
        fi
    else
        print_status "Uninstall cancelled"
    fi
}

# Function to show status
show_status() {
    local env=$1
    local config_info=$(get_env_config $env)
    local namespace=$(echo $config_info | cut -d' ' -f2)
    
    print_status "Checking $env environment status..."
    
    # Helm release status
    echo "=== Helm Release Status ==="
    if helm status $APP_NAME --namespace $namespace 2>/dev/null; then
        echo ""
    else
        print_warning "No Helm release found in namespace: $namespace"
        echo ""
    fi
    
    # Pod status
    echo "=== Pod Status ==="
    kubectl get pods -l app.kubernetes.io/name=$CHART_NAME --namespace $namespace 2>/dev/null || print_warning "No pods found"
    echo ""
    
    # Service status
    echo "=== Service Status ==="
    kubectl get svc -l app.kubernetes.io/name=$CHART_NAME --namespace $namespace 2>/dev/null || print_warning "No services found"
    echo ""
    
    # SecretProviderClass status (if Vault enabled)
    echo "=== SecretProviderClass Status ==="
    kubectl get secretproviderclass vault-secrets --namespace $namespace 2>/dev/null || print_warning "No SecretProviderClass found"
}

# Function to run tests
run_tests() {
    local env=$1
    local config_info=$(get_env_config $env)
    local namespace=$(echo $config_info | cut -d' ' -f2)
    
    print_status "Running tests for $env environment..."
    
    # Check if pods are running
    echo "=== Pod Health Check ==="
    local pod_count=$(kubectl get pods -l app.kubernetes.io/name=$CHART_NAME --namespace $namespace --no-headers 2>/dev/null | wc -l)
    
    if [ $pod_count -eq 0 ]; then
        print_error "No pods found in namespace: $namespace"
        return 1
    fi
    
    local running_pods=$(kubectl get pods -l app.kubernetes.io/name=$CHART_NAME --namespace $namespace --no-headers | grep Running | wc -l)
    print_status "$running_pods/$pod_count pods are running"
    
    # Test service connectivity
    echo ""
    echo "=== Service Connectivity ==="
    kubectl get endpoints -l app.kubernetes.io/name=$CHART_NAME --namespace $namespace
    
    # Test Vault secret injection (if enabled)
    echo ""
    echo "=== Vault Secret Test ==="
    if kubectl get secretproviderclass vault-secrets --namespace $namespace &>/dev/null; then
        kubectl describe secretproviderclass vault-secrets --namespace $namespace | grep -A 5 "Events:" || true
        print_success "SecretProviderClass is configured"
    else
        print_warning "Vault integration not configured"
    fi
    
    # Test external Datadog connectivity (if a pod is available)
    echo ""
    echo "=== External Datadog Test ==="
    local pod_name=$(kubectl get pods -l app.kubernetes.io/name=$CHART_NAME --namespace $namespace --no-headers | head -1 | awk '{print $1}')
    
    if [ -n "$pod_name" ]; then
        if kubectl exec $pod_name --namespace $namespace -- nc -zv datadog-agent.datadog.svc.cluster.local 8125 2>/dev/null; then
            print_success "External Datadog connectivity OK"
        else
            print_warning "Cannot connect to external Datadog agent (this might be expected)"
        fi
    fi
    
    print_success "Tests completed"
}

# Function to show logs
show_logs() {
    local env=$1
    local config_info=$(get_env_config $env)
    local namespace=$(echo $config_info | cut -d' ' -f2)
    
    print_status "Showing logs for $env environment..."
    kubectl logs -f deployment/$APP_NAME-$CHART_NAME --namespace $namespace
}

# Function to generate templates
generate_templates() {
    local env=$1
    local config_info=$(get_env_config $env)
    local values_file=$(echo $config_info | cut -d' ' -f1)
    
    print_status "Generating templates for $env environment..."
    helm template $APP_NAME . --values $values_file
}

# Main script
main() {
    # Check if no arguments provided
    if [ $# -eq 0 ]; then
        show_usage
        exit 1
    fi
    
    # Parse arguments
    local environment=${1:-}
    local action=${2:-install}
    
    # Validate environment
    case $environment in
        dev|uat|prod)
            ;;
        *)
            print_error "Invalid environment: $environment"
            show_usage
            exit 1
            ;;
    esac
    
    # Check prerequisites
    check_prerequisites
    
    # Execute action
    case $action in
        install|upgrade)
            deploy $environment $action
            ;;
        uninstall)
            uninstall $environment
            ;;
        status)
            show_status $environment
            ;;
        test)
            run_tests $environment
            ;;
        logs)
            show_logs $environment
            ;;
        template)
            generate_templates $environment
            ;;
        *)
            print_error "Invalid action: $action"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"