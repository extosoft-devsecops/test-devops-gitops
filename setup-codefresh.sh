#!/bin/bash

# ===================================================================
# Setup Codefresh for Direct Kubernetes Deployment
# ===================================================================

set -e

echo "🚀 Setting up Codefresh for Kubernetes Deployment"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ===================================================================
# ตรวจสอบ Prerequisites
# ===================================================================

echo "📋 Checking prerequisites..."
echo ""

# ตรวจสอบ codefresh CLI
if ! command -v codefresh &> /dev/null; then
    echo -e "${YELLOW}⚠${NC}  Codefresh CLI not found. Installing..."

    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install codefresh
    else
        curl -L https://github.com/codefresh-io/cli/releases/latest/download/codefresh-linux-amd64 -o /usr/local/bin/codefresh
        chmod +x /usr/local/bin/codefresh
    fi

    echo -e "${GREEN}✓${NC} Codefresh CLI installed"
else
    echo -e "${GREEN}✓${NC} Codefresh CLI is installed"
fi

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

# ===================================================================
# Login to Codefresh
# ===================================================================

echo "🔐 Codefresh Authentication"
echo ""

if [ -z "$CODEFRESH_API_KEY" ]; then
    echo -e "${YELLOW}⚠${NC}  CODEFRESH_API_KEY environment variable not set"
    echo ""
    echo "Please get your API key from:"
    echo "  https://g.codefresh.io/user/settings → Generate → API Keys"
    echo ""
    read -p "Enter your Codefresh API Key: " CODEFRESH_API_KEY
fi

echo "Authenticating with Codefresh..."
codefresh auth create-context --api-key "$CODEFRESH_API_KEY"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Successfully authenticated with Codefresh"
else
    echo -e "${RED}✗${NC} Failed to authenticate. Please check your API key."
    exit 1
fi

echo ""

# ===================================================================
# Add Kubernetes Cluster
# ===================================================================

echo "☸️  Adding Kubernetes Cluster to Codefresh"
echo ""

# ดึง cluster contexts
CONTEXTS=$(kubectl config get-contexts -o name)

echo "Available Kubernetes contexts:"
echo "$CONTEXTS" | nl
echo ""

read -p "Select cluster number (or enter context name): " CLUSTER_INPUT

if [[ "$CLUSTER_INPUT" =~ ^[0-9]+$ ]]; then
    CLUSTER_CONTEXT=$(echo "$CONTEXTS" | sed -n "${CLUSTER_INPUT}p")
else
    CLUSTER_CONTEXT="$CLUSTER_INPUT"
fi

echo "Selected cluster: $CLUSTER_CONTEXT"
echo ""

# กำหนดชื่อ cluster ใน Codefresh
read -p "Enter a name for this cluster in Codefresh (default: ${CLUSTER_CONTEXT}): " CLUSTER_NAME
CLUSTER_NAME=${CLUSTER_NAME:-$CLUSTER_CONTEXT}

echo "Adding cluster '$CLUSTER_NAME' to Codefresh..."

# ตรวจสอบว่า cluster มีอยู่แล้วหรือไม่
if codefresh get clusters | grep -q "$CLUSTER_NAME"; then
    echo -e "${YELLOW}⚠${NC}  Cluster '$CLUSTER_NAME' already exists in Codefresh"
else
    # เพิ่ม cluster
    codefresh create context kubernetes \
        --name "$CLUSTER_NAME" \
        --cluster-name "$CLUSTER_CONTEXT"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} Cluster added successfully"
    else
        echo -e "${RED}✗${NC} Failed to add cluster"
        echo "You may need to add it manually in Codefresh UI:"
        echo "  https://g.codefresh.io/account-admin/integrations/kubernetes"
    fi
fi

echo ""

# ===================================================================
# Create or Update Pipeline
# ===================================================================

echo "📦 Creating/Updating Pipeline"
echo ""

PROJECT_NAME="test-devops"
PIPELINE_NAME="test-devops-deploy"

# ตรวจสอบว่า project มีอยู่หรือไม่
if ! codefresh get projects | grep -q "$PROJECT_NAME"; then
    echo "Creating project '$PROJECT_NAME'..."
    codefresh create project "$PROJECT_NAME" --tags "kubernetes,helm,deployment"
fi

# ตรวจสอบว่า pipeline มีอยู่หรือไม่
if codefresh get pipelines | grep -q "$PIPELINE_NAME"; then
    echo -e "${YELLOW}⚠${NC}  Pipeline '$PIPELINE_NAME' already exists"
    read -p "Update existing pipeline? (y/n): " UPDATE_PIPELINE

    if [[ "$UPDATE_PIPELINE" =~ ^[Yy]$ ]]; then
        echo "Updating pipeline..."
        codefresh replace pipeline \
            --name "$PIPELINE_NAME" \
            --project "$PROJECT_NAME" \
            --spec-yaml codefresh.yaml

        echo -e "${GREEN}✓${NC} Pipeline updated"
    fi
else
    echo "Creating pipeline '$PIPELINE_NAME'..."
    codefresh create pipeline \
        --name "$PIPELINE_NAME" \
        --project "$PROJECT_NAME" \
        --spec-yaml codefresh.yaml

    echo -e "${GREEN}✓${NC} Pipeline created"
fi

echo ""

# ===================================================================
# Configure Variables
# ===================================================================

echo "⚙️  Configuring Pipeline Variables"
echo ""

# KUBE_CONTEXT
echo "Setting KUBE_CONTEXT variable..."
codefresh create variable KUBE_CONTEXT="$CLUSTER_CONTEXT" \
    --pipeline "$PIPELINE_NAME" \
    --type string \
    --description "Kubernetes cluster context" || echo "Variable may already exist"

# SLACK_WEBHOOK_URL (optional)
read -p "Do you want to configure Slack notifications? (y/n): " SETUP_SLACK

if [[ "$SETUP_SLACK" =~ ^[Yy]$ ]]; then
    read -p "Enter Slack Webhook URL: " SLACK_URL
    codefresh create variable SLACK_WEBHOOK_URL="$SLACK_URL" \
        --pipeline "$PIPELINE_NAME" \
        --type string \
        --encrypted \
        --description "Slack webhook URL for notifications" || echo "Variable may already exist"
fi

echo -e "${GREEN}✓${NC} Variables configured"
echo ""

# ===================================================================
# Setup Git Integration
# ===================================================================

echo "🔗 Git Integration"
echo ""

REPO_URL="https://github.com/extosoft-devsecops/test-devops-gitops.git"

echo "Repository: $REPO_URL"
echo ""
echo "Please ensure your GitHub repository is connected to Codefresh:"
echo "  1. Go to: https://g.codefresh.io/account-admin/integrations/git"
echo "  2. Add GitHub integration if not already added"
echo "  3. Grant access to repository: extosoft-devsecops/test-devops-gitops"
echo ""

read -p "Press Enter when ready to continue..."

# ===================================================================
# Create Triggers
# ===================================================================

echo "🎯 Creating Pipeline Triggers"
echo ""

# Development trigger
echo "Creating develop branch trigger..."
codefresh create trigger "$PIPELINE_NAME-develop" \
    --pipeline "$PIPELINE_NAME" \
    --type git \
    --provider github \
    --repo "extosoft-devsecops/test-devops-gitops" \
    --branch-regex "^develop$" \
    --event push || echo "Trigger may already exist"

# UAT trigger
echo "Creating uat branch trigger..."
codefresh create trigger "$PIPELINE_NAME-uat" \
    --pipeline "$PIPELINE_NAME" \
    --type git \
    --provider github \
    --repo "extosoft-devsecops/test-devops-gitops" \
    --branch-regex "^uat$" \
    --event push || echo "Trigger may already exist"

# Production trigger
echo "Creating main branch trigger..."
codefresh create trigger "$PIPELINE_NAME-main" \
    --pipeline "$PIPELINE_NAME" \
    --type git \
    --provider github \
    --repo "extosoft-devsecops/test-devops-gitops" \
    --branch-regex "^main$" \
    --event push || echo "Trigger may already exist"

echo -e "${GREEN}✓${NC} Triggers created"
echo ""

# ===================================================================
# Test Pipeline
# ===================================================================

echo "🧪 Testing Pipeline Configuration"
echo ""

read -p "Do you want to test run the pipeline? (y/n): " TEST_RUN

if [[ "$TEST_RUN" =~ ^[Yy]$ ]]; then
    echo "Running test build on develop branch..."
    BUILD_ID=$(codefresh run "$PIPELINE_NAME" --branch develop --detach | grep -oP 'Build ID: \K[a-f0-9]+')

    if [ -n "$BUILD_ID" ]; then
        echo -e "${GREEN}✓${NC} Build started: $BUILD_ID"
        echo ""
        echo "View build at:"
        echo "  https://g.codefresh.io/build/$BUILD_ID"
        echo ""
        echo "Follow logs:"
        echo "  codefresh logs $BUILD_ID --follow"
    fi
fi

echo ""

# ===================================================================
# Summary
# ===================================================================

echo "================================"
echo "✅ Setup Complete!"
echo "================================"
echo ""
echo "📝 Summary:"
echo "  Project: $PROJECT_NAME"
echo "  Pipeline: $PIPELINE_NAME"
echo "  Cluster: $CLUSTER_NAME ($CLUSTER_CONTEXT)"
echo ""
echo "🎯 Triggers:"
echo "  develop → test-devops-develop namespace"
echo "  uat → test-devops-uat namespace"
echo "  main → test-devops-prod namespace"
echo ""
echo "🔗 Useful Links:"
echo "  Pipeline: https://g.codefresh.io/pipelines/$PIPELINE_NAME"
echo "  Builds: https://g.codefresh.io/builds"
echo "  Clusters: https://g.codefresh.io/account-admin/integrations/kubernetes"
echo ""
echo "📚 Next Steps:"
echo "  1. Push code to trigger deployment:"
echo "     git push origin develop"
echo ""
echo "  2. View builds:"
echo "     codefresh get builds --pipeline $PIPELINE_NAME"
echo ""
echo "  3. Monitor deployment:"
echo "     kubectl get pods -n test-devops-develop -w"
echo ""
echo "📖 Documentation:"
echo "  See CODEFRESH_DEPLOY.md for detailed usage"
echo ""

