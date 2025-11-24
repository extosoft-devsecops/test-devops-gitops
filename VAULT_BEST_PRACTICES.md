# Vault Secrets Management Best Practices Guide

## วันที่: 24 พฤศจิกายน 2025

## สารบัญ
1. [Service Account Configuration](#service-account-configuration)
2. [Vault Secrets Structure](#vault-secrets-structure)
3. [SecretProviderClass Configuration](#secretproviderclass-configuration)
4. [Deployment Integration](#deployment-integration)
5. [Security Best Practices](#security-best-practices)
6. [Environment Setup Checklist](#environment-setup-checklist)
7. [Troubleshooting Guide](#troubleshooting-guide)

---

## Service Account Configuration

### ✅ Best Practice: ใช้ Service Account เดียวกันทุก Environment

**เหตุผล:**
- ง่ายต่อการจัดการ Vault role configuration
- Consistent across environments
- ลดความซับซ้อนในการ maintain

### Helm Values Configuration

```yaml
# values-<environment>.yaml
serviceAccount:
  create: true
  name: "vault-auth"
  automount: true
  annotations: {}
```

### ❌ สิ่งที่ควรหลีกเลี่ยง

```yaml
# ❌ อย่าใช้ค่า default (ไม่กำหนด serviceAccount.name)
# Pod จะใช้ชื่อที่ generate จาก template ซึ่งแตกต่างกันในแต่ละ environment

# ❌ อย่าใช้ชื่อ service account ที่แตกต่างกันในแต่ละ environment
serviceAccount:
  name: "test-devops-uat"  # ❌ ทำให้ Vault config ซับซ้อน
```

### Kubernetes ClusterRoleBinding

สร้าง ClusterRoleBinding สำหรับแต่ละ namespace:

```bash
# Template
kubectl create clusterrolebinding vault-auth-delegator-<env> \
  --clusterrole=system:auth-delegator \
  --serviceaccount=<namespace>:vault-auth

# ตัวอย่าง
kubectl create clusterrolebinding vault-auth-delegator-develop \
  --clusterrole=system:auth-delegator \
  --serviceaccount=gke-nonprod-test-devops-develop:vault-auth

kubectl create clusterrolebinding vault-auth-delegator-uat \
  --clusterrole=system:auth-delegator \
  --serviceaccount=gke-nonprod-test-devops-uat:vault-auth

kubectl create clusterrolebinding vault-auth-delegator-staging \
  --clusterrole=system:auth-delegator \
  --serviceaccount=gke-nonprod-test-devops-staging:vault-auth

kubectl create clusterrolebinding vault-auth-delegator-prod \
  --clusterrole=system:auth-delegator \
  --serviceaccount=gke-prod-test-devops-prod:vault-auth
```

**หมายเหตุ:** ClusterRole `system:auth-delegator` จำเป็นสำหรับ Vault Kubernetes authentication

---

## Vault Secrets Structure

### ✅ Recommended Secret Path Structure

```
secret/
├── k8s/
│   ├── test-devops-develop/
│   │   ├── SERVICE_NAME
│   │   ├── NODE_ENV
│   │   ├── PORT
│   │   ├── DATABASE_URL
│   │   ├── API_KEY
│   │   └── ...
│   ├── test-devops-uat/
│   │   └── ...
│   ├── test-devops-staging/
│   │   └── ...
│   └── test-devops-prod/
│       └── ...
```

### Vault KV v2 Path Format

**สำคัญ:** KV v2 engine ต้องใช้ `/data/` ใน path

```bash
# ✅ ถูกต้อง - KV v2 format
secretPath: "secret/data/k8s/test-devops-uat"

# ❌ ผิด - ขาด /data/
secretPath: "secret/k8s/test-devops-uat"
```

### สร้าง Secrets ใน Vault

```bash
# ตั้งค่า Vault environment
export VAULT_ADDR="https://vault-devops.extosoft.app"
export VAULT_TOKEN="<your-vault-token>"

# สร้าง secrets สำหรับ environment
vault kv put secret/k8s/test-devops-develop \
  SERVICE_NAME="test-devops" \
  NODE_ENV="development" \
  PORT="3000" \
  ENABLE_METRICS="true" \
  DD_DOGSTATSD_PORT="8125" \
  DD_AGENT_HOST="datadog-agent.datadog.svc.cluster.local" \
  DATABASE_URL="postgresql://..." \
  API_KEY="dev-api-key-xxx"

vault kv put secret/k8s/test-devops-uat \
  SERVICE_NAME="test-devops" \
  NODE_ENV="uat" \
  PORT="3000" \
  ENABLE_METRICS="true" \
  DD_DOGSTATSD_PORT="8125" \
  DD_AGENT_HOST="datadog-agent.datadog.svc.cluster.local" \
  DATABASE_URL="postgresql://..." \
  API_KEY="uat-api-key-xxx"
```

### ตรวจสอบ Secrets

```bash
# อ่าน secrets
vault kv get secret/k8s/test-devops-uat

# List secrets
vault kv list secret/k8s/

# ดู metadata
vault kv metadata get secret/k8s/test-devops-uat
```

---

## SecretProviderClass Configuration

### ✅ Best Practice Template

```yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: vault-secrets
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "test-devops.labels" . | nindent 4 }}
spec:
  provider: vault
  parameters:
    # Vault server configuration
    vaultAddress: "{{ .Values.vault.address }}"
    vaultSkipTLSVerify: "{{ .Values.vault.skipTLSVerify }}"  # ใช้ "false" ใน production
    roleName: "{{ .Values.vault.roleName }}"
    
    # Secrets mapping
    objects: |
      - objectName: "service-name"
        secretPath: "{{ .Values.vault.secrets.secretPath }}"
        secretKey: "SERVICE_NAME"
      - objectName: "node-env"
        secretPath: "{{ .Values.vault.secrets.secretPath }}"
        secretKey: "NODE_ENV"
      - objectName: "port"
        secretPath: "{{ .Values.vault.secrets.secretPath }}"
        secretKey: "PORT"
      - objectName: "enable-metrics"
        secretPath: "{{ .Values.vault.secrets.secretPath }}"
        secretKey: "ENABLE_METRICS"
      - objectName: "database-url"
        secretPath: "{{ .Values.vault.secrets.secretPath }}"
        secretKey: "DATABASE_URL"
      - objectName: "api-key"
        secretPath: "{{ .Values.vault.secrets.secretPath }}"
        secretKey: "API_KEY"
  
  # สร้าง Kubernetes Secret จาก Vault secrets
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
        - objectName: "database-url"
          key: "database-url"
        - objectName: "api-key"
          key: "api-key"
```

### Key Naming Convention

**✅ แนะนำ:**
- `objectName`: ใช้ kebab-case (lowercase with dashes)
- `secretKey`: ใช้ UPPER_SNAKE_CASE (ตามที่เก็บใน Vault)
- `key`: ใช้ kebab-case (สำหรับ Kubernetes Secret)

```yaml
- objectName: "database-url"      # kebab-case
  secretPath: "..."
  secretKey: "DATABASE_URL"       # UPPER_SNAKE_CASE
  
data:
  - objectName: "database-url"
    key: "database-url"           # kebab-case
```

### ❌ สิ่งที่ควรหลีกเลี่ยง

```yaml
# ❌ objectName และ secretKey ไม่ตรงกัน
- objectName: "db-url"
  secretKey: "DATABASE_URL"

# ❌ Hard-coded secretPath
secretPath: "secret/data/k8s/test-devops-uat"  # ควรใช้ template variable
```

---

## Deployment Integration

### ✅ Best Practice Deployment Configuration

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "test-devops.fullname" . }}
spec:
  template:
    spec:
      # ใช้ service account ที่กำหนด
      serviceAccountName: {{ include "test-devops.serviceAccountName" . }}
      
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          
          # Mount secrets เป็น environment variables
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
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: app-secrets
                  key: database-url
            - name: API_KEY
              valueFrom:
                secretKeyRef:
                  name: app-secrets
                  key: api-key
          
          # Mount CSI volume
          volumeMounts:
            - name: vault-secrets
              mountPath: "/mnt/secrets-store"
              readOnly: true
      
      # CSI driver volume
      volumes:
        - name: vault-secrets
          csi:
            driver: secrets-store.csi.k8s.io
            readOnly: true
            volumeAttributes:
              secretProviderClass: "vault-secrets"
```

### Environment Variables vs Files

**ใช้ Environment Variables เมื่อ:**
- Application ต้องการค่า config แบบ simple (port, flags, URLs)
- ค่าไม่มีการเปลี่ยนแปลงบ่อย
- ค่าไม่ใหญ่เกินไป

**ใช้ Files เมื่อ:**
- Secrets เป็น certificates, private keys
- ค่ามีขนาดใหญ่ (> 1KB)
- Application อ่าน config จากไฟล์โดยตรง

```yaml
# ตัวอย่างการใช้ทั้งสองวิธี
env:
  - name: DATABASE_URL
    valueFrom:
      secretKeyRef:
        name: app-secrets
        key: database-url

volumeMounts:
  - name: vault-secrets
    mountPath: "/mnt/secrets-store"
    readOnly: true
  # อ่าน certificate จากไฟล์
  # /mnt/secrets-store/tls-cert
  # /mnt/secrets-store/tls-key
```

---

## Security Best Practices

### 1. TLS Verification

```yaml
# ❌ Development/UAT only
vault:
  skipTLSVerify: "true"

# ✅ Production
vault:
  skipTLSVerify: "false"
  # ต้องมี valid TLS certificate
```

### 2. Vault Policy - Least Privilege Principle

```hcl
# k8s-policy.hcl
# ✅ อนุญาตเฉพาะ path ที่จำเป็น
path "secret/data/k8s/*" {
  capabilities = ["read"]
}

path "secret/metadata/k8s/*" {
  capabilities = ["list", "read"]
}

# ❌ อย่าให้สิทธิ์มากเกินไป
path "secret/*" {
  capabilities = ["create", "read", "update", "delete", "list"]  # ❌ Too permissive
}
```

### 3. Token TTL Configuration

```bash
# ✅ ตั้งค่า TTL ที่เหมาะสม
vault write auth/kubernetes/role/k8s-app \
    bound_service_account_names="vault-auth" \
    bound_service_account_namespaces="gke-nonprod-test-devops-develop,gke-nonprod-test-devops-uat" \
    policies="k8s-policy" \
    ttl=24h \              # Token หมดอายุใน 24 ชั่วโมง
    max_ttl=48h            # Maximum TTL

# ❌ อย่าตั้ง TTL ยาวเกินไป
ttl=8760h  # ❌ 1 ปี - นานเกินไป
```

### 4. Secret Rotation

```yaml
# Pod Annotations สำหรับ auto-reload secrets
podAnnotations:
  vault.hashicorp.com/agent-inject: "true"
  vault.hashicorp.com/agent-inject-secret-config: "secret/k8s/test-devops-uat"
  vault.hashicorp.com/agent-cache-enable: "true"
```

### 5. Audit Logging

```bash
# เปิด audit log ใน Vault
vault audit enable file file_path=/vault/logs/audit.log

# ตรวจสอบ authentication attempts
vault audit list
```

### 6. Network Policies

```yaml
# จำกัด network access ไปยัง Vault
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-vault-access
  namespace: gke-nonprod-test-devops-uat
spec:
  podSelector:
    matchLabels:
      app: test-devops
  policyTypes:
    - Egress
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: vault
      ports:
        - protocol: TCP
          port: 8200
```

---

## Environment Setup Checklist

### Pre-requisites
- [ ] Vault server running และ accessible
- [ ] Kubernetes cluster configured
- [ ] Secrets Store CSI Driver installed
- [ ] Vault CSI Provider installed
- [ ] kubectl access to cluster

### Vault Configuration

```bash
# 1. Enable Kubernetes auth method (ครั้งเดียว)
vault auth enable kubernetes

# 2. Configure Kubernetes auth
export K8S_HOST="https://<kubernetes-api-server>"
export K8S_CA_CERT=$(kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 --decode)
export SA_JWT_TOKEN=$(kubectl create token vault-auth -n default)

vault write auth/kubernetes/config \
    token_reviewer_jwt="$SA_JWT_TOKEN" \
    kubernetes_host="$K8S_HOST" \
    kubernetes_ca_cert="$K8S_CA_CERT" \
    issuer="$K8S_HOST"

# 3. Create policy
vault policy write k8s-policy /path/to/k8s-policy.hcl

# 4. Create role
vault write auth/kubernetes/role/k8s-app \
    bound_service_account_names="vault-auth" \
    bound_service_account_namespaces="gke-nonprod-test-devops-develop,gke-nonprod-test-devops-uat,gke-nonprod-test-devops-staging" \
    policies="k8s-policy" \
    ttl=24h
```

### Kubernetes Configuration

```bash
# 1. Create namespace
kubectl create namespace gke-nonprod-test-devops-<env>

# 2. Create service account (if not using Helm)
kubectl create serviceaccount vault-auth -n gke-nonprod-test-devops-<env>

# 3. Create ClusterRoleBinding
kubectl create clusterrolebinding vault-auth-delegator-<env> \
  --clusterrole=system:auth-delegator \
  --serviceaccount=gke-nonprod-test-devops-<env>:vault-auth

# 4. Verify service account
kubectl get serviceaccount vault-auth -n gke-nonprod-test-devops-<env>
```

### Application Configuration

```bash
# 1. Update values-<env>.yaml
cat > values-<env>.yaml <<EOF
serviceAccount:
  create: true
  name: "vault-auth"

vault:
  enabled: true
  address: "https://vault-devops.extosoft.app"
  skipTLSVerify: "false"  # true for non-prod
  roleName: "k8s-app"
  secrets:
    secretPath: "secret/data/k8s/test-devops-<env>"
EOF

# 2. Create secrets in Vault
vault kv put secret/k8s/test-devops-<env> \
  SERVICE_NAME="test-devops" \
  NODE_ENV="<env>" \
  PORT="3000" \
  # ... other secrets

# 3. Deploy application
helm upgrade --install test-devops-<env> ./helm/test-devops \
  -f values-<env>.yaml \
  -n gke-nonprod-test-devops-<env>

# 4. Verify deployment
kubectl get pods -n gke-nonprod-test-devops-<env>
kubectl logs -n gke-nonprod-test-devops-<env> <pod-name>
```

---

## Troubleshooting Guide

### Error: "permission denied" (403)

**อาการ:**
```
Code: 403. Errors: * permission denied
```

**สาเหตุที่เป็นไปได้:**
1. Service account ไม่ตรงกับ Vault role
2. Namespace ไม่ตรงกับ Vault role
3. ขาด ClusterRoleBinding
4. Vault policy ไม่อนุญาต

**วิธีแก้:**
```bash
# 1. ตรวจสอบ service account ที่ pod ใช้
kubectl get pod <pod-name> -n <namespace> -o jsonpath='{.spec.serviceAccountName}'

# 2. ตรวจสอบ Vault role
vault read auth/kubernetes/role/k8s-app

# 3. ตรวจสอบ ClusterRoleBinding
kubectl get clusterrolebinding | grep vault-auth

# 4. ตรวจสอบ Vault policy
vault policy read k8s-policy

# 5. Test authentication manually
kubectl run -it vault-test --rm --image=hashicorp/vault:1.18.0 \
  --serviceaccount=vault-auth \
  -n <namespace> -- sh

# Inside the pod:
export VAULT_ADDR="https://vault-devops.extosoft.app"
JWT=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
vault write auth/kubernetes/login role=k8s-app jwt=$JWT
```

### Error: "couldn't read secret"

**อาการ:**
```
couldn't read secret "service-name": failed to login
```

**สาเหตุ:**
1. Secret ไม่มีใน Vault
2. secretPath ไม่ถูกต้อง
3. secretKey ไม่ตรงกับชื่อใน Vault

**วิธีแก้:**
```bash
# 1. ตรวจสอบ secret ใน Vault
vault kv get secret/k8s/test-devops-<env>

# 2. ตรวจสอบ secretPath ใน SecretProviderClass
kubectl get secretproviderclass vault-secrets -n <namespace> -o yaml

# 3. สร้าง secret ที่ขาด
vault kv put secret/k8s/test-devops-<env> \
  SERVICE_NAME="test-devops" \
  # ... other keys
```

### Error: "ContainerCreating" stuck

**อาการ:**
Pod ติดสถานะ ContainerCreating เป็นเวลานาน

**วิธีแก้:**
```bash
# 1. ตรวจสอบ events
kubectl describe pod <pod-name> -n <namespace>

# 2. ตรวจสอบ CSI driver logs
kubectl logs -n kube-system -l app=secrets-store-csi-driver

# 3. ตรวจสอบ Vault provider logs
kubectl logs -n kube-system -l app=vault-csi-provider

# 4. Restart pod
kubectl delete pod <pod-name> -n <namespace>
```

### Error: "secret not synced to Kubernetes"

**อาการ:**
Secrets ไม่ถูก sync เป็น Kubernetes Secret

**วิธีแก้:**
```bash
# 1. ตรวจสอบว่า secretObjects ถูกกำหนดใน SecretProviderClass
kubectl get secretproviderclass vault-secrets -n <namespace> -o yaml | grep -A 20 secretObjects

# 2. ตรวจสอบ Kubernetes Secret
kubectl get secret app-secrets -n <namespace>

# 3. Force refresh โดยการ restart pod
kubectl rollout restart deployment/<deployment-name> -n <namespace>
```

### Debugging Commands

```bash
# ตรวจสอบ SecretProviderClass
kubectl get secretproviderclass -n <namespace>
kubectl describe secretproviderclass vault-secrets -n <namespace>

# ตรวจสอบ ServiceAccount
kubectl get serviceaccount vault-auth -n <namespace>
kubectl describe serviceaccount vault-auth -n <namespace>

# ตรวจสอบ ClusterRoleBinding
kubectl get clusterrolebinding vault-auth-delegator-<env>
kubectl describe clusterrolebinding vault-auth-delegator-<env>

# ตรวจสอบ Pod
kubectl get pods -n <namespace>
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>

# ตรวจสอบ Vault
vault status
vault read auth/kubernetes/config
vault read auth/kubernetes/role/k8s-app
vault policy read k8s-policy
vault kv list secret/k8s/
vault kv get secret/k8s/test-devops-<env>
```

---

## Example: Complete Setup Script

```bash
#!/bin/bash
# setup-vault-environment.sh

set -e

# Variables
ENV="${1:-develop}"
NAMESPACE="gke-nonprod-test-devops-${ENV}"
SERVICE_ACCOUNT="vault-auth"
VAULT_ROLE="k8s-app"
VAULT_ADDR="https://vault-devops.extosoft.app"

echo "=== Setting up Vault for environment: ${ENV} ==="

# 1. Create namespace
echo "Creating namespace: ${NAMESPACE}"
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# 2. Create service account
echo "Creating service account: ${SERVICE_ACCOUNT}"
kubectl create serviceaccount ${SERVICE_ACCOUNT} -n ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# 3. Create ClusterRoleBinding
echo "Creating ClusterRoleBinding"
kubectl create clusterrolebinding vault-auth-delegator-${ENV} \
  --clusterrole=system:auth-delegator \
  --serviceaccount=${NAMESPACE}:${SERVICE_ACCOUNT} \
  --dry-run=client -o yaml | kubectl apply -f -

# 4. Update Vault role (add namespace)
echo "Updating Vault role"
export VAULT_TOKEN="${VAULT_TOKEN}"
export VAULT_ADDR="${VAULT_ADDR}"

# Get current namespaces
CURRENT_NAMESPACES=$(vault read -field=bound_service_account_namespaces auth/kubernetes/role/${VAULT_ROLE} | tr ',' '\n')
NEW_NAMESPACES="${CURRENT_NAMESPACES},${NAMESPACE}"

vault write auth/kubernetes/role/${VAULT_ROLE} \
    bound_service_account_names="${SERVICE_ACCOUNT}" \
    bound_service_account_namespaces="${NEW_NAMESPACES}" \
    policies="k8s-policy" \
    ttl=24h

# 5. Create sample secrets in Vault
echo "Creating sample secrets in Vault"
vault kv put secret/k8s/test-devops-${ENV} \
  SERVICE_NAME="test-devops" \
  NODE_ENV="${ENV}" \
  PORT="3000" \
  ENABLE_METRICS="true" \
  DD_DOGSTATSD_PORT="8125" \
  DD_AGENT_HOST="datadog-agent.datadog.svc.cluster.local"

echo "=== Setup completed successfully ==="
echo ""
echo "Next steps:"
echo "1. Update values-${ENV}.yaml with serviceAccount.name: '${SERVICE_ACCOUNT}'"
echo "2. Deploy application: helm upgrade --install test-devops-${ENV} ./helm/test-devops -f values-${ENV}.yaml -n ${NAMESPACE}"
echo "3. Verify: kubectl get pods -n ${NAMESPACE}"
```

**การใช้งาน:**
```bash
chmod +x setup-vault-environment.sh
./setup-vault-environment.sh develop
./setup-vault-environment.sh uat
./setup-vault-environment.sh staging
```

---

## Summary Checklist

### For Each New Environment

**Kubernetes:**
- [ ] Namespace created
- [ ] Service account `vault-auth` created
- [ ] ClusterRoleBinding created
- [ ] values-<env>.yaml configured with `serviceAccount.name: "vault-auth"`

**Vault:**
- [ ] Namespace added to Vault role `bound_service_account_namespaces`
- [ ] Secrets created in `secret/k8s/test-devops-<env>`
- [ ] Policy allows read access to the path
- [ ] Vault role TTL configured appropriately

**Application:**
- [ ] SecretProviderClass references correct `secretPath`
- [ ] Deployment uses correct `serviceAccountName`
- [ ] Environment variables mapped correctly
- [ ] CSI volume mounted

**Verification:**
- [ ] Pod status is `Running`
- [ ] Pod has READY 1/1
- [ ] Secrets mounted correctly
- [ ] Application can access secrets
- [ ] No errors in pod logs

---

**อัพเดทล่าสุด:** 24 พฤศจิกายน 2025
**Version:** 1.0
**Maintainer:** DevSecOps Team
