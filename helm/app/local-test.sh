#!/bin/bash

# Local Kubernetes Testing Script
# Usage: ./local-test.sh [start|stop|restart|status|logs]

set -e

NAMESPACE="test-devops-local"
RELEASE_NAME="test-devops-local"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
check_context() {
    # Get available contexts
    AVAILABLE_CONTEXTS=$(kubectl config get-contexts -o name 2>/dev/null || echo "")
    CURRENT_CONTEXT=$(kubectl config current-context 2>/dev/null || echo "")

    # Check if docker-desktop exists
    if echo "$AVAILABLE_CONTEXTS" | grep -q "^docker-desktop$"; then
        if [[ "$CURRENT_CONTEXT" != "docker-desktop" ]]; then
            echo -e "${YELLOW}⚠️  Switching to docker-desktop context${NC}"
            kubectl config use-context docker-desktop
            CURRENT_CONTEXT="docker-desktop"
        fi
        echo -e "${GREEN}✓ Using context: docker-desktop${NC}"
        return 0
    fi

    # Check if minikube exists
    if echo "$AVAILABLE_CONTEXTS" | grep -q "^minikube$"; then
        if [[ "$CURRENT_CONTEXT" != "minikube" ]]; then
            echo -e "${YELLOW}⚠️  Switching to minikube context${NC}"
            kubectl config use-context minikube
            CURRENT_CONTEXT="minikube"
        fi
        echo -e "${GREEN}✓ Using context: minikube${NC}"
        return 0
    fi

    # No local context found
    if [[ -z "$CURRENT_CONTEXT" ]]; then
        echo -e "${RED}❌ No Kubernetes context found${NC}"
    else
        echo -e "${YELLOW}⚠️  Current context: $CURRENT_CONTEXT${NC}"
    fi

    echo ""
    echo -e "${YELLOW}No local Kubernetes cluster detected.${NC}"
    echo ""
    echo "Available options:"
    echo ""
    echo "1️⃣  Enable Kubernetes in Docker Desktop:"
    echo "   - Open Docker Desktop"
    echo "   - Go to Settings → Kubernetes"
    echo "   - ✅ Enable Kubernetes"
    echo "   - Click 'Apply & Restart'"
    echo "   - Wait 2-5 minutes"
    echo ""
    echo "2️⃣  Or use Minikube:"
    echo "   brew install minikube"
    echo "   minikube start --driver=docker"
    echo ""
    echo "3️⃣  Or use Kind:"
    echo "   brew install kind"
    echo "   kind create cluster"
    echo ""

    if [[ -n "$CURRENT_CONTEXT" ]]; then
        echo "4️⃣  Or continue with current context: $CURRENT_CONTEXT"
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${GREEN}✓ Using context: $CURRENT_CONTEXT${NC}"
            return 0
        fi
    fi

    exit 1
}

check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}❌ kubectl not found${NC}"
        exit 1
    fi

    if ! kubectl cluster-info &> /dev/null; then
        echo -e "${RED}❌ Cannot connect to Kubernetes cluster${NC}"
        echo "Please ensure Kubernetes is running in Docker Desktop or start Minikube"
        exit 1
    fi

    echo -e "${GREEN}✓ kubectl is working${NC}"
}

check_helm() {
    if ! command -v helm &> /dev/null; then
        echo -e "${RED}❌ helm not found${NC}"
        echo "Install: brew install helm"
        exit 1
    fi
    echo -e "${GREEN}✓ helm is installed${NC}"
}

build_image() {
    echo -e "${YELLOW}🔨 Building Docker image...${NC}"
    cd "$PROJECT_ROOT"

    docker build -t test-devops:latest .

    echo -e "${GREEN}✓ Image built successfully${NC}"
}

deploy() {
    echo -e "${YELLOW}📦 Deploying to local Kubernetes...${NC}"
    cd "$SCRIPT_DIR"

    # Create namespace if not exists
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

    # Deploy with Helm
    helm upgrade --install $RELEASE_NAME . \
        -f values-local.yaml \
        --namespace $NAMESPACE \
        --wait \
        --timeout 2m

    echo -e "${GREEN}✓ Deployment complete!${NC}"
}

status() {
    echo -e "${YELLOW}📊 Checking status...${NC}"
    echo ""

    echo "=== Helm Release ==="
    helm status $RELEASE_NAME -n $NAMESPACE 2>/dev/null || echo "Not installed"
    echo ""

    echo "=== Pods ==="
    kubectl get pods -n $NAMESPACE -o wide
    echo ""

    echo "=== Services ==="
    kubectl get svc -n $NAMESPACE
    echo ""

    echo "=== Access URLs ==="
    CONTEXT=$(kubectl config current-context)
    if [[ "$CONTEXT" == "minikube" ]]; then
        echo "Run: minikube service $RELEASE_NAME-test-devops-app -n $NAMESPACE"
    else
        echo "NodePort: http://localhost:30080"
        echo "Port Forward: kubectl port-forward -n $NAMESPACE svc/$RELEASE_NAME-test-devops-app 3000:3000"
    fi
}

logs() {
    echo -e "${YELLOW}📋 Showing logs...${NC}"
    kubectl logs -n $NAMESPACE -l app=test-devops-app --tail=100 -f
}

stop() {
    echo -e "${YELLOW}🛑 Stopping...${NC}"
    helm uninstall $RELEASE_NAME -n $NAMESPACE 2>/dev/null || echo "Already uninstalled"
    echo -e "${GREEN}✓ Stopped${NC}"
}

cleanup() {
    echo -e "${YELLOW}🗑️  Cleaning up...${NC}"
    helm uninstall $RELEASE_NAME -n $NAMESPACE 2>/dev/null || true
    kubectl delete namespace $NAMESPACE 2>/dev/null || true
    echo -e "${GREEN}✓ Cleanup complete${NC}"
}

test_app() {
    echo -e "${YELLOW}🧪 Testing application...${NC}"

    # Wait for pod to be ready
    echo "Waiting for pod to be ready..."
    kubectl wait --for=condition=ready pod -l app=test-devops-app -n $NAMESPACE --timeout=60s

    # Test via port-forward
    echo "Testing via port-forward..."
    kubectl port-forward -n $NAMESPACE svc/$RELEASE_NAME-test-devops-app 3000:3000 &
    PF_PID=$!

    sleep 3

    if curl -s http://localhost:3000/ > /dev/null; then
        echo -e "${GREEN}✓ Application is responding!${NC}"
        curl http://localhost:3000/
    else
        echo -e "${RED}❌ Application not responding${NC}"
    fi

    kill $PF_PID 2>/dev/null || true
}

# Main
case "${1:-}" in
    start)
        echo -e "${GREEN}🚀 Starting local Kubernetes deployment...${NC}"
        check_context
        check_kubectl
        check_helm
        build_image
        deploy
        status
        echo ""
        echo -e "${GREEN}🎉 Deployment successful!${NC}"
        echo ""
        echo "Next steps:"
        echo "  - View status: ./local-test.sh status"
        echo "  - View logs: ./local-test.sh logs"
        echo "  - Test app: ./local-test.sh test"
        echo "  - Stop: ./local-test.sh stop"
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        sleep 2
        build_image
        deploy
        status
        ;;
    status)
        status
        ;;
    logs)
        logs
        ;;
    test)
        test_app
        ;;
    cleanup)
        cleanup
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|test|cleanup}"
        echo ""
        echo "Commands:"
        echo "  start   - Build image and deploy to local Kubernetes"
        echo "  stop    - Remove deployment"
        echo "  restart - Stop and start again"
        echo "  status  - Show deployment status"
        echo "  logs    - Show application logs"
        echo "  test    - Test application endpoint"
        echo "  cleanup - Remove everything including namespace"
        exit 1
        ;;
esac

