# Vault + Kubernetes Setup Guide - เริ่มต้นจากศูนย์

## วันที่: 24 พฤศจิกายน 2025

---

## สารบัญ
1. [Prerequisites & Installation](#prerequisites--installation)
2. [Vault Server Setup](#vault-server-setup)
3. [Kubernetes Cluster Preparation](#kubernetes-cluster-preparation)
4. [Service Account Creation](#service-account-creation)
5. [Vault Kubernetes Auth Configuration](#vault-kubernetes-auth-configuration)
6. [Policy & Role Setup](#policy--role-setup)
7. [Application Integration](#application-integration)
8. [Testing & Verification](#testing--verification)

---

## Prerequisites & Installation

### ✅ สิ่งที่ต้องมีก่อนเริ่ม

```bash
# 1. Kubernetes Cluster (GKE, EKS, AKS, หรือ local)
# 2. kubectl CLI installed
# 3. Helm installed (optional แต่แนะนำ)
# 4. Vault server accessible
# 5. Vault CLI installed
```

### ติดตั้ง Vault CLI

```bash
# Ubuntu/Debian
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install vault

# macOS
brew tap hashicorp/tap
brew install hashicorp/tap/vault

# ตรวจสอบการติดตั้ง
vault version
```

### ติดตั้ง kubectl

```bash
# Ubuntu/Debian
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# macOS
brew install kubectl

# ตรวจสอบการติดตั้ง
kubectl version --client
```

---

## Vault Server Setup

### 1. ติดตั้ง Vault Server (ถ้ายังไม่มี)

#### ตัวเลือก A: ใช้ Docker (สำหรับ Development)

```bash
# สร้าง directory สำหรับเก็บข้อมูล
mkdir -p ~/vault/data
mkdir -p ~/vault/config
mkdir -p ~/vault/logs

# สร้าง config file
cat > ~/vault/config/vault.hcl <<EOF
storage "file" {
  path = "/vault/data"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1  # เปิดใช้ TLS ใน production
}

ui = true

api_addr = "http://0.0.0.0:8200"
EOF

# Run Vault container
docker run -d \
  --name vault \
  -p 8200:8200 \
  -v ~/vault/data:/vault/data \
  -v ~/vault/config:/vault/config \
  -v ~/vault/logs:/vault/logs \
  --cap-add=IPC_LOCK \
  hashicorp/vault:1.18.0 server
```

#### ตัวเลือก B: ติดตั้งบน Kubernetes

```bash
# เพิ่ม Helm repository
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

# สร้าง namespace
kubectl create namespace vault

# Install Vault
helm install vault hashicorp/vault \
  --namespace vault \
  --set "server.dev.enabled=false" \
  --set "server.ha.enabled=true" \
  --set "server.ha.replicas=3" \
  --set "ui.enabled=true" \
  --set "ui.serviceType=LoadBalancer"
```

### 2. Initialize Vault

```bash
# ตั้งค่า environment variable
export VAULT_ADDR='http://localhost:8200'

# Initialize Vault (ครั้งแรกเท่านั้น)
vault operator init

# บันทึกข้อมูลนี้ไว้ในที่ปลอดภัย!
# Output จะได้:
# Unseal Key 1: xxxxxxxxxxxxxxxxxxxx
# Unseal Key 2: xxxxxxxxxxxxxxxxxxxx
# Unseal Key 3: xxxxxxxxxxxxxxxxxxxx
# Unseal Key 4: xxxxxxxxxxxxxxxxxxxx
# Unseal Key 5: xxxxxxxxxxxxxxxxxxxx
# Initial Root Token: hvs.xxxxxxxxxxxxxxxxxxxx
```

### 3. Unseal Vault

```bash
# ต้อง unseal ด้วย key อย่างน้อย 3 keys (default threshold)
vault operator unseal <Unseal-Key-1>
vault operator unseal <Unseal-Key-2>
vault operator unseal <Unseal-Key-3>

# ตรวจสอบสถานะ
vault status
```

### 4. Login to Vault

```bash
# Login ด้วย root token
export VAULT_TOKEN='hvs.xxxxxxxxxxxxxxxxxxxx'

# หรือ
vault login
# Token: <paste-root-token>
```

### 5. Enable KV Secrets Engine

```bash
# Enable KV version 2
vault secrets enable -path=secret kv-v2

# ตรวจสอบ
vault secrets list
```

---

## Kubernetes Cluster Preparation

### 1. เชื่อมต่อกับ Kubernetes Cluster

```bash
# GKE
gcloud container clusters get-credentials <cluster-name> \
  --zone <zone> \
  --project <project-id>

# EKS
aws eks update-kubeconfig \
  --region <region> \
  --name <cluster-name>

# ตรวจสอบการเชื่อมต่อ
kubectl cluster-info
kubectl get nodes
```

### 2. ติดตั้ง Secrets Store CSI Driver

```bash
# เพิ่ม Helm repository
helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm repo update

# ติดตั้ง CSI Driver
helm install csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver \
  --namespace kube-system \
  --set syncSecret.enabled=true \
  --set enableSecretRotation=true

# ตรวจสอบการติดตั้ง
kubectl get pods -n kube-system -l app=secrets-store-csi-driver
```

### 3. ติดตั้ง Vault CSI Provider

```bash
# สร้าง DaemonSet สำหรับ Vault Provider
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: vault-csi-provider
  namespace: kube-system
spec:
  selector:
    matchLabels:
      app: vault-csi-provider
  template:
    metadata:
      labels:
        app: vault-csi-provider
    spec:
      serviceAccountName: vault-csi-provider
      containers:
        - name: provider-vault-installer
          image: hashicorp/vault-csi-provider:1.4.0
          imagePullPolicy: Always
          args:
            - -endpoint=/provider/vault.sock
            - -debug=false
          resources:
            requests:
              cpu: 50m
              memory: 100Mi
            limits:
              cpu: 100m
              memory: 200Mi
          volumeMounts:
            - name: providervol
              mountPath: "/provider"
          livenessProbe:
            httpGet:
              path: /health/ready
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 5
      volumes:
        - name: providervol
          hostPath:
            path: "/etc/kubernetes/secrets-store-csi-providers"
      nodeSelector:
        kubernetes.io/os: linux
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: vault-csi-provider
  namespace: kube-system
EOF

# ตรวจสอบการติดตั้ง
kubectl get daemonset -n kube-system vault-csi-provider
kubectl get pods -n kube-system -l app=vault-csi-provider
```

---

## Service Account Creation

### 1. สร้าง Namespace สำหรับแต่ละ Environment

```bash
# Development
kubectl create namespace gke-nonprod-test-devops-develop

# UAT
kubectl create namespace gke-nonprod-test-devops-uat

# Staging
kubectl create namespace gke-nonprod-test-devops-staging

# Production (ถ้ามี)
kubectl create namespace gke-prod-test-devops-prod

# ตรวจสอบ
kubectl get namespaces | grep test-devops
```

### 2. สร้าง Service Account ใน Default Namespace (สำหรับ Vault Auth)

```bash
# สร้าง service account ใน default namespace
kubectl create serviceaccount vault-auth -n default

# ตรวจสอบ
kubectl get serviceaccount vault-auth -n default

# สร้าง token สำหรับ service account (Kubernetes 1.24+)
kubectl create token vault-auth -n default --duration=87600h > /tmp/vault-auth-token.txt

# ดูข้อมูล service account
kubectl describe serviceaccount vault-auth -n default
```

### 3. สร้าง Service Account ในแต่ละ Application Namespace

```bash
# สร้าง service account สำหรับแต่ละ environment
ENVS="develop uat staging"

for ENV in $ENVS; do
  NAMESPACE="gke-nonprod-test-devops-${ENV}"
  
  echo "Creating service account in ${NAMESPACE}..."
  
  kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: vault-auth
  namespace: ${NAMESPACE}
  labels:
    app: test-devops
    environment: ${ENV}
automountServiceAccountToken: true
EOF

done

# ตรวจสอบ
kubectl get serviceaccount vault-auth -n gke-nonprod-test-devops-develop
kubectl get serviceaccount vault-auth -n gke-nonprod-test-devops-uat
kubectl get serviceaccount vault-auth -n gke-nonprod-test-devops-staging
```

### 4. สร้าง ClusterRoleBinding

```bash
# สร้าง ClusterRoleBinding สำหรับ default namespace (สำหรับ Vault auth config)
kubectl create clusterrolebinding vault-auth-delegator \
  --clusterrole=system:auth-delegator \
  --serviceaccount=default:vault-auth

# สร้าง ClusterRoleBinding สำหรับแต่ละ application namespace
ENVS="develop uat staging"

for ENV in $ENVS; do
  NAMESPACE="gke-nonprod-test-devops-${ENV}"
  
  echo "Creating ClusterRoleBinding for ${NAMESPACE}..."
  
  kubectl create clusterrolebinding vault-auth-delegator-${ENV} \
    --clusterrole=system:auth-delegator \
    --serviceaccount=${NAMESPACE}:vault-auth
done

# ตรวจสอบ
kubectl get clusterrolebinding | grep vault-auth
```

**อธิบาย ClusterRole `system:auth-delegator`:**
- ให้สิทธิ์ service account ในการ validate tokens กับ Kubernetes API
- จำเป็นสำหรับ Vault Kubernetes authentication method
- ไม่มีสิทธิ์อื่นๆ (ปลอดภัย)

---

## Vault Kubernetes Auth Configuration

### 1. รวบรวมข้อมูล Kubernetes Cluster

```bash
# 1. Kubernetes API Server URL
export K8S_HOST=$(kubectl config view --raw -o jsonpath='{.clusters[0].cluster.server}')
echo "Kubernetes Host: ${K8S_HOST}"

# 2. Kubernetes CA Certificate
kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' \
  | base64 --decode > /tmp/k8s-ca.crt
echo "CA Certificate saved to /tmp/k8s-ca.crt"

# ดู CA cert (ต้องขึ้นต้นด้วย -----BEGIN CERTIFICATE-----)
head -3 /tmp/k8s-ca.crt

# 3. Service Account JWT Token (ใช้ token ที่สร้างไว้)
# Token อยู่ใน /tmp/vault-auth-token.txt แล้ว
echo "Token saved to /tmp/vault-auth-token.txt"
```

### 2. Enable Kubernetes Auth Method ใน Vault

```bash
# ตั้งค่า Vault environment
export VAULT_ADDR='https://vault-devops.extosoft.app'  # เปลี่ยนเป็น URL ของคุณ
export VAULT_TOKEN='hvs.xxxxxxxxxxxxxxxxxxxx'           # Root token หรือ token ที่มีสิทธิ์

# Enable Kubernetes auth method
vault auth enable kubernetes

# ตรวจสอบ
vault auth list
```

### 3. Configure Kubernetes Auth Method

```bash
# อ่านค่าจาก files
export K8S_CA_CERT=$(cat /tmp/k8s-ca.crt)
export SA_JWT_TOKEN=$(cat /tmp/vault-auth-token.txt)

# Configure Vault Kubernetes auth
vault write auth/kubernetes/config \
    token_reviewer_jwt="${SA_JWT_TOKEN}" \
    kubernetes_host="${K8S_HOST}" \
    kubernetes_ca_cert="${K8S_CA_CERT}" \
    issuer="${K8S_HOST}"

# ตรวจสอบ configuration
vault read auth/kubernetes/config
```

**Expected Output:**
```
Key                       Value
---                       -----
kubernetes_host           https://x.x.x.x
kubernetes_ca_cert        -----BEGIN CERTIFICATE-----...
token_reviewer_jwt_set    true
issuer                    https://x.x.x.x
```

---

## Policy & Role Setup

### 1. สร้าง Vault Policy

```bash
# สร้าง policy file
cat > /tmp/k8s-policy.hcl <<EOF
# Allow reading secrets from k8s path
path "secret/data/k8s/*" {
  capabilities = ["read"]
}

# Allow listing secrets metadata
path "secret/metadata/k8s/*" {
  capabilities = ["list", "read"]
}
EOF

# สร้าง policy ใน Vault
vault policy write k8s-policy /tmp/k8s-policy.hcl

# ตรวจสอบ policy
vault policy read k8s-policy
```

### 2. สร้าง Kubernetes Auth Role

```bash
# สร้าง role สำหรับ applications
vault write auth/kubernetes/role/k8s-app \
    bound_service_account_names="vault-auth" \
    bound_service_account_namespaces="default,gke-nonprod-test-devops-develop,gke-nonprod-test-devops-uat,gke-nonprod-test-devops-staging" \
    policies="k8s-policy" \
    ttl=24h \
    max_ttl=48h

# ตรวจสอบ role
vault read auth/kubernetes/role/k8s-app
```

**Expected Output:**
```
Key                                         Value
---                                         -----
alias_name_source                           serviceaccount_uid
bound_service_account_names                 [vault-auth]
bound_service_account_namespaces            [default gke-nonprod-test-devops-develop gke-nonprod-test-devops-uat gke-nonprod-test-devops-staging]
policies                                    [k8s-policy]
ttl                                         24h
max_ttl                                     48h
```

### 3. สร้าง Secrets ใน Vault

```bash
# สร้าง secrets สำหรับ Development
vault kv put secret/k8s/test-devops-develop \
  SERVICE_NAME="test-devops" \
  NODE_ENV="development" \
  PORT="3000" \
  ENABLE_METRICS="true" \
  DD_DOGSTATSD_PORT="8125" \
  DD_AGENT_HOST="datadog-agent.datadog.svc.cluster.local"

# สร้าง secrets สำหรับ UAT
vault kv put secret/k8s/test-devops-uat \
  SERVICE_NAME="test-devops" \
  NODE_ENV="uat" \
  PORT="3000" \
  ENABLE_METRICS="true" \
  DD_DOGSTATSD_PORT="8125" \
  DD_AGENT_HOST="datadog-agent.datadog.svc.cluster.local"

# สร้าง secrets สำหรับ Staging
vault kv put secret/k8s/test-devops-staging \
  SERVICE_NAME="test-devops" \
  NODE_ENV="staging" \
  PORT="3000" \
  ENABLE_METRICS="true" \
  DD_DOGSTATSD_PORT="8125" \
  DD_AGENT_HOST="datadog-agent.datadog.svc.cluster.local"

# ตรวจสอบ secrets
vault kv list secret/k8s/
vault kv get secret/k8s/test-devops-develop
```

---

## Application Integration

### 1. สร้าง SecretProviderClass

```bash
# สร้าง SecretProviderClass สำหรับแต่ละ environment
ENVS="develop uat staging"

for ENV in $ENVS; do
  NAMESPACE="gke-nonprod-test-devops-${ENV}"
  
  echo "Creating SecretProviderClass in ${NAMESPACE}..."
  
  kubectl apply -f - <<EOF
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: vault-secrets
  namespace: ${NAMESPACE}
spec:
  provider: vault
  parameters:
    vaultAddress: "https://vault-devops.extosoft.app"
    vaultSkipTLSVerify: "true"  # เปลี่ยนเป็น "false" ใน production
    roleName: "k8s-app"
    objects: |
      - objectName: "service-name"
        secretPath: "secret/data/k8s/test-devops-${ENV}"
        secretKey: "SERVICE_NAME"
      - objectName: "node-env"
        secretPath: "secret/data/k8s/test-devops-${ENV}"
        secretKey: "NODE_ENV"
      - objectName: "port"
        secretPath: "secret/data/k8s/test-devops-${ENV}"
        secretKey: "PORT"
      - objectName: "enable-metrics"
        secretPath: "secret/data/k8s/test-devops-${ENV}"
        secretKey: "ENABLE_METRICS"
      - objectName: "dd-dogstatsd-port"
        secretPath: "secret/data/k8s/test-devops-${ENV}"
        secretKey: "DD_DOGSTATSD_PORT"
      - objectName: "dd-agent-host"
        secretPath: "secret/data/k8s/test-devops-${ENV}"
        secretKey: "DD_AGENT_HOST"
  secretObjects:
    - secretName: app-secrets
      type: Opaque
      data:
        - objectName: "service-name"
          key: "service-name"
        - objectName: "node-env"
          key: "node-env"
        - objectName: "port"
          key: "port"
        - objectName: "enable-metrics"
          key: "enable-metrics"
        - objectName: "dd-dogstatsd-port"
          key: "dd-dogstatsd-port"
        - objectName: "dd-agent-host"
          key: "dd-agent-host"
EOF

done

# ตรวจสอบ
kubectl get secretproviderclass -n gke-nonprod-test-devops-develop
kubectl get secretproviderclass -n gke-nonprod-test-devops-uat
kubectl get secretproviderclass -n gke-nonprod-test-devops-staging
```

### 2. สร้าง Test Deployment

```bash
# สร้าง test deployment สำหรับ UAT
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-vault-integration
  namespace: gke-nonprod-test-devops-uat
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test-vault
  template:
    metadata:
      labels:
        app: test-vault
    spec:
      serviceAccountName: vault-auth
      containers:
        - name: app
          image: nginx:alpine
          ports:
            - containerPort: 80
          env:
            - name: PORT
              valueFrom:
                secretKeyRef:
                  name: app-secrets
                  key: port
            - name: SERVICE_NAME
              valueFrom:
                secretKeyRef:
                  name: app-secrets
                  key: service-name
            - name: NODE_ENV
              valueFrom:
                secretKeyRef:
                  name: app-secrets
                  key: node-env
          volumeMounts:
            - name: vault-secrets
              mountPath: "/mnt/secrets-store"
              readOnly: true
      volumes:
        - name: vault-secrets
          csi:
            driver: secrets-store.csi.k8s.io
            readOnly: true
            volumeAttributes:
              secretProviderClass: "vault-secrets"
EOF

# ตรวจสอบ deployment
kubectl get pods -n gke-nonprod-test-devops-uat
```

---

## Testing & Verification

### 1. ตรวจสอบ Pod Status

```bash
# ดู pod status
kubectl get pods -n gke-nonprod-test-devops-uat

# Expected: READY 1/1, STATUS Running

# ดู events
kubectl get events -n gke-nonprod-test-devops-uat --sort-by='.lastTimestamp'
```

### 2. ตรวจสอบ Secrets

```bash
# ตรวจสอบว่า Kubernetes Secret ถูกสร้าง
kubectl get secret app-secrets -n gke-nonprod-test-devops-uat

# ดูข้อมูลใน secret
kubectl get secret app-secrets -n gke-nonprod-test-devops-uat -o yaml

# Decode secret values
kubectl get secret app-secrets -n gke-nonprod-test-devops-uat \
  -o jsonpath='{.data.service-name}' | base64 --decode
echo ""
```

### 3. ตรวจสอบ Environment Variables ใน Pod

```bash
# เข้าไปใน pod
POD_NAME=$(kubectl get pods -n gke-nonprod-test-devops-uat -l app=test-vault -o jsonpath='{.items[0].metadata.name}')

# ดู environment variables
kubectl exec -it ${POD_NAME} -n gke-nonprod-test-devops-uat -- env | grep -E "PORT|SERVICE_NAME|NODE_ENV"

# Expected output:
# PORT=3000
# SERVICE_NAME=test-devops
# NODE_ENV=uat
```

### 4. ตรวจสอบ Mounted Secrets

```bash
# ดูไฟล์ที่ mount จาก Vault
kubectl exec -it ${POD_NAME} -n gke-nonprod-test-devops-uat -- ls -la /mnt/secrets-store/

# อ่านค่าจากไฟล์
kubectl exec -it ${POD_NAME} -n gke-nonprod-test-devops-uat -- cat /mnt/secrets-store/service-name
```

### 5. Test Manual Authentication

```bash
# สร้าง test pod
kubectl run vault-test -it --rm \
  --image=hashicorp/vault:1.18.0 \
  --serviceaccount=vault-auth \
  -n gke-nonprod-test-devops-uat \
  -- sh

# ใน pod ทดสอบ authentication
export VAULT_ADDR="https://vault-devops.extosoft.app"
export VAULT_SKIP_VERIFY=true

# อ่าน service account token
JWT=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)

# Login to Vault
vault write auth/kubernetes/login role=k8s-app jwt=$JWT

# Expected output จะได้ token
# ลอง read secret
vault kv get secret/k8s/test-devops-uat

# Exit pod
exit
```

### 6. ตรวจสอบ Logs

```bash
# ดู pod logs
kubectl logs ${POD_NAME} -n gke-nonprod-test-devops-uat

# ดู CSI driver logs
kubectl logs -n kube-system -l app=secrets-store-csi-driver --tail=50

# ดู Vault provider logs
kubectl logs -n kube-system -l app=vault-csi-provider --tail=50
```

---

## Complete Setup Script

บันทึกเป็นไฟล์ `setup-vault-k8s.sh`:

```bash
#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
VAULT_ADDR="${VAULT_ADDR:-https://vault-devops.extosoft.app}"
VAULT_TOKEN="${VAULT_TOKEN}"
ENVIRONMENTS="develop uat staging"
NAMESPACE_PREFIX="gke-nonprod-test-devops"

echo -e "${GREEN}=== Vault + Kubernetes Setup Script ===${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"
command -v kubectl >/dev/null 2>&1 || { echo -e "${RED}kubectl is not installed${NC}"; exit 1; }
command -v vault >/dev/null 2>&1 || { echo -e "${RED}vault is not installed${NC}"; exit 1; }

if [ -z "${VAULT_TOKEN}" ]; then
  echo -e "${RED}VAULT_TOKEN is not set${NC}"
  exit 1
fi

export VAULT_ADDR
export VAULT_TOKEN

echo -e "${GREEN}✓ Prerequisites OK${NC}"
echo ""

# Step 1: Create namespaces
echo -e "${YELLOW}Step 1: Creating namespaces...${NC}"
for ENV in ${ENVIRONMENTS}; do
  NAMESPACE="${NAMESPACE_PREFIX}-${ENV}"
  kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
  echo -e "${GREEN}✓ Created namespace: ${NAMESPACE}${NC}"
done
echo ""

# Step 2: Create service accounts
echo -e "${YELLOW}Step 2: Creating service accounts...${NC}"

# Default namespace
kubectl create serviceaccount vault-auth -n default --dry-run=client -o yaml | kubectl apply -f -
echo -e "${GREEN}✓ Created service account in default namespace${NC}"

# Application namespaces
for ENV in ${ENVIRONMENTS}; do
  NAMESPACE="${NAMESPACE_PREFIX}-${ENV}"
  kubectl create serviceaccount vault-auth -n ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
  echo -e "${GREEN}✓ Created service account in ${NAMESPACE}${NC}"
done
echo ""

# Step 3: Create ClusterRoleBindings
echo -e "${YELLOW}Step 3: Creating ClusterRoleBindings...${NC}"

kubectl create clusterrolebinding vault-auth-delegator \
  --clusterrole=system:auth-delegator \
  --serviceaccount=default:vault-auth \
  --dry-run=client -o yaml | kubectl apply -f -
echo -e "${GREEN}✓ Created ClusterRoleBinding for default namespace${NC}"

for ENV in ${ENVIRONMENTS}; do
  NAMESPACE="${NAMESPACE_PREFIX}-${ENV}"
  kubectl create clusterrolebinding vault-auth-delegator-${ENV} \
    --clusterrole=system:auth-delegator \
    --serviceaccount=${NAMESPACE}:vault-auth \
    --dry-run=client -o yaml | kubectl apply -f -
  echo -e "${GREEN}✓ Created ClusterRoleBinding for ${NAMESPACE}${NC}"
done
echo ""

# Step 4: Configure Vault Kubernetes auth
echo -e "${YELLOW}Step 4: Configuring Vault Kubernetes auth...${NC}"

# Get Kubernetes info
K8S_HOST=$(kubectl config view --raw -o jsonpath='{.clusters[0].cluster.server}')
kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 --decode > /tmp/k8s-ca.crt
SA_JWT_TOKEN=$(kubectl create token vault-auth -n default --duration=87600h)

echo "Kubernetes Host: ${K8S_HOST}"

# Enable auth method if not already enabled
vault auth list | grep -q kubernetes || vault auth enable kubernetes
echo -e "${GREEN}✓ Kubernetes auth method enabled${NC}"

# Configure auth method
vault write auth/kubernetes/config \
    token_reviewer_jwt="${SA_JWT_TOKEN}" \
    kubernetes_host="${K8S_HOST}" \
    kubernetes_ca_cert="$(cat /tmp/k8s-ca.crt)" \
    issuer="${K8S_HOST}"
echo -e "${GREEN}✓ Configured Kubernetes auth${NC}"
echo ""

# Step 5: Create policy
echo -e "${YELLOW}Step 5: Creating Vault policy...${NC}"

cat > /tmp/k8s-policy.hcl <<EOF
path "secret/data/k8s/*" {
  capabilities = ["read"]
}

path "secret/metadata/k8s/*" {
  capabilities = ["list", "read"]
}
EOF

vault policy write k8s-policy /tmp/k8s-policy.hcl
echo -e "${GREEN}✓ Created policy: k8s-policy${NC}"
echo ""

# Step 6: Create role
echo -e "${YELLOW}Step 6: Creating Vault role...${NC}"

NAMESPACES="default"
for ENV in ${ENVIRONMENTS}; do
  NAMESPACES="${NAMESPACES},${NAMESPACE_PREFIX}-${ENV}"
done

vault write auth/kubernetes/role/k8s-app \
    bound_service_account_names="vault-auth" \
    bound_service_account_namespaces="${NAMESPACES}" \
    policies="k8s-policy" \
    ttl=24h \
    max_ttl=48h
echo -e "${GREEN}✓ Created role: k8s-app${NC}"
echo ""

# Step 7: Create secrets
echo -e "${YELLOW}Step 7: Creating secrets in Vault...${NC}"

for ENV in ${ENVIRONMENTS}; do
  vault kv put secret/k8s/test-devops-${ENV} \
    SERVICE_NAME="test-devops" \
    NODE_ENV="${ENV}" \
    PORT="3000" \
    ENABLE_METRICS="true" \
    DD_DOGSTATSD_PORT="8125" \
    DD_AGENT_HOST="datadog-agent.datadog.svc.cluster.local"
  echo -e "${GREEN}✓ Created secrets for ${ENV}${NC}"
done
echo ""

# Step 8: Create SecretProviderClass
echo -e "${YELLOW}Step 8: Creating SecretProviderClass...${NC}"

for ENV in ${ENVIRONMENTS}; do
  NAMESPACE="${NAMESPACE_PREFIX}-${ENV}"
  
  kubectl apply -f - <<EOF
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: vault-secrets
  namespace: ${NAMESPACE}
spec:
  provider: vault
  parameters:
    vaultAddress: "${VAULT_ADDR}"
    vaultSkipTLSVerify: "true"
    roleName: "k8s-app"
    objects: |
      - objectName: "service-name"
        secretPath: "secret/data/k8s/test-devops-${ENV}"
        secretKey: "SERVICE_NAME"
      - objectName: "node-env"
        secretPath: "secret/data/k8s/test-devops-${ENV}"
        secretKey: "NODE_ENV"
      - objectName: "port"
        secretPath: "secret/data/k8s/test-devops-${ENV}"
        secretKey: "PORT"
      - objectName: "enable-metrics"
        secretPath: "secret/data/k8s/test-devops-${ENV}"
        secretKey: "ENABLE_METRICS"
      - objectName: "dd-dogstatsd-port"
        secretPath: "secret/data/k8s/test-devops-${ENV}"
        secretKey: "DD_DOGSTATSD_PORT"
      - objectName: "dd-agent-host"
        secretPath: "secret/data/k8s/test-devops-${ENV}"
        secretKey: "DD_AGENT_HOST"
  secretObjects:
    - secretName: app-secrets
      type: Opaque
      data:
        - objectName: "service-name"
          key: "service-name"
        - objectName: "node-env"
          key: "node-env"
        - objectName: "port"
          key: "port"
        - objectName: "enable-metrics"
          key: "enable-metrics"
        - objectName: "dd-dogstatsd-port"
          key: "dd-dogstatsd-port"
        - objectName: "dd-agent-host"
          key: "dd-agent-host"
EOF
  
  echo -e "${GREEN}✓ Created SecretProviderClass in ${NAMESPACE}${NC}"
done
echo ""

# Summary
echo -e "${GREEN}=== Setup Complete! ===${NC}"
echo ""
echo "Summary:"
echo "  - Namespaces created: ${ENVIRONMENTS}"
echo "  - Service accounts created in all namespaces"
echo "  - ClusterRoleBindings configured"
echo "  - Vault Kubernetes auth configured"
echo "  - Policy created: k8s-policy"
echo "  - Role created: k8s-app"
echo "  - Secrets created for all environments"
echo "  - SecretProviderClass created in all namespaces"
echo ""
echo "Next steps:"
echo "  1. Update your Helm values files with:"
echo "     serviceAccount:"
echo "       create: true"
echo "       name: \"vault-auth\""
echo ""
echo "  2. Deploy your application"
echo "  3. Verify with: kubectl get pods -n <namespace>"
echo ""

# Cleanup
rm -f /tmp/k8s-ca.crt /tmp/k8s-policy.hcl
```

**การใช้งาน:**

```bash
# ให้สิทธิ์ execute
chmod +x setup-vault-k8s.sh

# Run script
export VAULT_ADDR="https://vault-devops.extosoft.app"
export VAULT_TOKEN="hvs.xxxxxxxxxxxxxxxx"
./setup-vault-k8s.sh
```

---

## Summary Checklist

### ✅ ขั้นตอนที่เสร็จสมบูรณ์

- [ ] Vault Server ติดตั้งและ running
- [ ] Vault initialized และ unsealed
- [ ] KV secrets engine enabled
- [ ] Kubernetes cluster accessible
- [ ] Secrets Store CSI Driver installed
- [ ] Vault CSI Provider installed
- [ ] Namespaces created
- [ ] Service accounts created (default + app namespaces)
- [ ] ClusterRoleBindings created
- [ ] Kubernetes auth method enabled in Vault
- [ ] Vault Kubernetes auth configured
- [ ] Vault policy created
- [ ] Vault role created
- [ ] Secrets created in Vault
- [ ] SecretProviderClass created
- [ ] Test deployment successful

---

## Troubleshooting

หากพบปัญหา ให้ดู [VAULT_BEST_PRACTICES.md](VAULT_BEST_PRACTICES.md) ในหัวข้อ Troubleshooting Guide

---

**อัพเดทล่าสุด:** 24 พฤศจิกายน 2025
**Version:** 1.0
**Maintainer:** DevSecOps Team
