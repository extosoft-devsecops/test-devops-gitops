#!/bin/bash

# Quick setup script for local Kubernetes testing
# This will guide you through setting up a local Kubernetes cluster

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}🚀 Local Kubernetes Setup Helper${NC}"
echo ""

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl is not installed${NC}"
    echo ""
    echo "Install kubectl:"
    echo "  brew install kubectl"
    echo ""
    exit 1
fi

echo -e "${GREEN}✓ kubectl is installed${NC}"

# Check for existing contexts
CONTEXTS=$(kubectl config get-contexts -o name 2>/dev/null || echo "")

if [[ -z "$CONTEXTS" ]]; then
    echo -e "${YELLOW}⚠️  No Kubernetes contexts found${NC}"
    echo ""
    echo "You need to set up a local Kubernetes cluster."
    echo ""
    echo "Choose one of the following options:"
    echo ""
    echo -e "${GREEN}1️⃣  Docker Desktop Kubernetes (Recommended)${NC}"
    echo "   - Easiest to use, has GUI"
    echo "   - Open Docker Desktop"
    echo "   - Go to Settings → Kubernetes"
    echo "   - ✅ Enable Kubernetes"
    echo "   - Click 'Apply & Restart'"
    echo "   - Wait 2-5 minutes"
    echo ""
    echo -e "${GREEN}2️⃣  Minikube${NC}"
    echo "   brew install minikube"
    echo "   minikube start --driver=docker --cpus=4 --memory=4096"
    echo ""
    echo -e "${GREEN}3️⃣  Kind (Kubernetes in Docker)${NC}"
    echo "   brew install kind"
    echo "   kind create cluster"
    echo ""
    echo -e "${GREEN}4️⃣  Use Docker Compose instead (No Kubernetes)${NC}"
    echo "   cd ../.."
    echo "   make run-localhost"
    echo ""

    read -p "Which option do you want to use? (1-4): " choice

    case $choice in
        1)
            echo ""
            echo -e "${BLUE}Opening Docker Desktop instructions...${NC}"
            echo ""
            echo "Steps:"
            echo "1. Open Docker Desktop"
            echo "2. Click on Settings/Preferences"
            echo "3. Go to Kubernetes tab"
            echo "4. Check 'Enable Kubernetes'"
            echo "5. Click 'Apply & Restart'"
            echo "6. Wait for Kubernetes to start (2-5 minutes)"
            echo ""
            echo "After setup, run this script again or run:"
            echo "  make local-start"
            echo ""
            ;;
        2)
            echo ""
            echo -e "${BLUE}Installing and starting Minikube...${NC}"
            if ! command -v minikube &> /dev/null; then
                echo "Installing Minikube..."
                brew install minikube
            fi
            echo "Starting Minikube..."
            minikube start --driver=docker --cpus=4 --memory=4096
            echo ""
            echo -e "${GREEN}✅ Minikube is ready!${NC}"
            echo ""
            echo "Now you can run:"
            echo "  make local-start"
            echo ""
            ;;
        3)
            echo ""
            echo -e "${BLUE}Installing and setting up Kind...${NC}"
            if ! command -v kind &> /dev/null; then
                echo "Installing Kind..."
                brew install kind
            fi
            echo "Creating Kind cluster..."
            kind create cluster --name test-devops
            echo ""
            echo -e "${GREEN}✅ Kind cluster is ready!${NC}"
            echo ""
            echo "Now you can run:"
            echo "  make local-start"
            echo ""
            ;;
        4)
            echo ""
            echo -e "${BLUE}Switching to Docker Compose...${NC}"
            cd ../..
            echo "Starting with Docker Compose..."
            make run-localhost
            ;;
        *)
            echo ""
            echo -e "${RED}Invalid option${NC}"
            exit 1
            ;;
    esac
else
    echo ""
    echo "Available Kubernetes contexts:"
    kubectl config get-contexts
    echo ""

    CURRENT_CONTEXT=$(kubectl config current-context 2>/dev/null || echo "")

    if [[ -n "$CURRENT_CONTEXT" ]]; then
        echo -e "${GREEN}✓ Current context: $CURRENT_CONTEXT${NC}"

        # Test connection
        if kubectl cluster-info &> /dev/null; then
            echo -e "${GREEN}✓ Cluster is accessible${NC}"
            echo ""
            echo "You're all set! Run:"
            echo "  make local-start"
            echo ""
        else
            echo -e "${RED}❌ Cannot connect to cluster${NC}"
            echo ""
            echo "The cluster might not be running. Try:"
            echo "  - If using Docker Desktop: Check that Kubernetes is running"
            echo "  - If using Minikube: minikube start"
            echo "  - If using Kind: kind create cluster"
            echo ""
        fi
    else
        echo -e "${YELLOW}No context is currently active${NC}"
        echo ""
        echo "Select a context:"
        kubectl config use-context $(kubectl config get-contexts -o name | head -1)
    fi
fi

