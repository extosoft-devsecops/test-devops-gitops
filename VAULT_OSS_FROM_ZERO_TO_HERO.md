# Vault OSS - From Zero to Hero Guide

## 🎯 Complete Production-Ready Vault Deployment on Kubernetes

**วันที่:** 24 พฤศจิกายน 2025  
**Version:** 1.0  
**Target:** Production-ready HashiCorp Vault OSS on Kubernetes with domain exposure

---

## 📑 Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [Part 1: Kubernetes Preparation](#part-1-kubernetes-preparation)
4. [Part 2: Vault Installation on Kubernetes](#part-2-vault-installation-on-kubernetes)
5. [Part 3: Vault Initialization & Unsealing](#part-3-vault-initialization--unsealing)
6. [Part 4: Domain Exposure & Ingress Setup](#part-4-domain-exposure--ingress-setup)
7. [Part 5: TLS/SSL Certificate Setup](#part-5-tlsssl-certificate-setup)
8. [Part 6: High Availability Configuration](#part-6-high-availability-configuration)
9. [Part 7: Backup & Disaster Recovery](#part-7-backup--disaster-recovery)
10. [Part 8: Security Hardening](#part-8-security-hardening)
11. [Part 9: Monitoring & Logging](#part-9-monitoring--logging)
12. [Part 10: Application Integration](#part-10-application-integration)
13. [Troubleshooting Guide](#troubleshooting-guide)
14. [Production Checklist](#production-checklist)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Internet / External                       │
└───────────────────────────┬─────────────────────────────────┘
                            │
                    ┌───────▼────────┐
                    │  Load Balancer  │
                    │   (External)    │
                    └───────┬────────┘
                            │
                    ┌───────▼────────┐
                    │ Ingress Nginx  │
                    │  TLS Termination│
                    └───────┬────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
    ┌───▼────┐         ┌────▼───┐         ┌────▼───┐
    │ Vault  │◄────────► Vault  │◄────────► Vault  │
    │ Pod 1  │         │ Pod 2  │         │ Pod 3  │
    │ Active │         │Standby │         │Standby │
    └───┬────┘         └────┬───┘         └────┬───┘
        │                   │                   │
        └───────────────────┼───────────────────┘
                            │
                    ┌───────▼────────┐
                    │  Consul/Raft   │
                    │    Storage     │
                    │  (StatefulSet) │
                    └────────────────┘
```

**Components:**
- **Vault Pods:** 3 replicas for High Availability
- **Storage Backend:** Integrated Raft storage
- **Ingress:** Nginx Ingress Controller with TLS
- **Domain:** vault.domain.app
- **Auto-unseal:** Kubernetes secrets (for demo) or Cloud KMS (production)

---

## Prerequisites

### Required Tools

```bash
# 1. kubectl (Kubernetes CLI)
kubectl version --client

# 2. Helm (Package Manager)
helm version

# 3. OpenSSL (for certificate generation)
openssl version

# 4. jq (JSON processor)
jq --version

# 5. Access to Kubernetes cluster
kubectl cluster-info
```

### Cluster Requirements

- **Kubernetes Version:** 1.24+
- **Storage Class:** Available for PersistentVolumes
- **Ingress Controller:** Nginx Ingress installed
- **Resources:**
  - CPU: 3 cores minimum (1 core per Vault pod)
  - Memory: 6GB minimum (2GB per Vault pod)
  - Storage: 30GB minimum (10GB per Vault pod)

### DNS Requirements

- Domain name (e.g., `vault.domain.app`)
- DNS A record pointing to Load Balancer IP
- SSL certificate (Let's Encrypt or custom)

---

## Part 1: Kubernetes Preparation

### 1.1 Create Namespace

```bash
# สร้าง namespace สำหรับ Vault
kubectl create namespace vault

# ตั้งเป็น default namespace (optional)
kubectl config set-context --current --namespace=vault

# ตรวจสอบ
kubectl get namespace vault
```

### 1.2 Create Storage Class (if needed)

```bash
# ตรวจสอบ storage class ที่มีอยู่
kubectl get storageclass

# สำหรับ GKE
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: vault-storage
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-ssd
  replication-type: regional-pd
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
EOF

# สำหรับ AWS EKS
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: vault-storage
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp3
  iops: "3000"
  throughput: "125"
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
EOF
```

### 1.3 Install Nginx Ingress Controller (if not installed)

```bash
# เพิ่ม Helm repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install Nginx Ingress
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-type"="nlb" \
  --set controller.metrics.enabled=true

# ตรวจสอบการติดตั้ง
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx

# รอจนได้ External IP
kubectl get svc -n ingress-nginx ingress-nginx-controller -w
```

### 1.4 Update DNS Record

```bash
# รับ External IP ของ Load Balancer
EXTERNAL_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "External IP: ${EXTERNAL_IP}"

# สร้าง DNS A record
# vault.domain.app -> ${EXTERNAL_IP}

# สำหรับ Cloudflare (ตัวอย่าง)
# curl -X POST "https://api.cloudflare.com/client/v4/zones/{zone_id}/dns_records" \
#   -H "Authorization: Bearer {api_token}" \
#   -H "Content-Type: application/json" \
#   --data '{"type":"A","name":"vault","content":"'${EXTERNAL_IP}'","ttl":1,"proxied":false}'

# ทดสอบ DNS resolution
nslookup vault.domain.app
```

---

## Part 2: Vault Installation on Kubernetes

### 2.1 Add HashiCorp Helm Repository

```bash
# เพิ่ม HashiCorp Helm repo
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

# ค้นหา Vault chart versions
helm search repo hashicorp/vault --versions | head -10
```

### 2.2 Create Custom Values File

สร้างไฟล์ `vault-values.yaml`:

```yaml
# vault-values.yaml
global:
  enabled: true
  tlsDisable: false  # Enable TLS

injector:
  enabled: false  # ปิด injector ถ้าไม่ใช้

server:
  # Image configuration
  image:
    repository: "hashicorp/vault"
    tag: "1.18.0"
    pullPolicy: IfNotPresent

  # Resources
  resources:
    requests:
      memory: 2Gi
      cpu: 1000m
    limits:
      memory: 4Gi
      cpu: 2000m

  # Readiness probe
  readinessProbe:
    enabled: true
    path: "/v1/sys/health?standbyok=true&sealedcode=204&uninitcode=204"

  # Liveness probe
  livenessProbe:
    enabled: true
    path: "/v1/sys/health?standbyok=true"
    initialDelaySeconds: 60

  # Update strategy
  updateStrategyType: "RollingUpdate"

  # Security context
  securityContext:
    runAsNonRoot: true
    runAsUser: 100
    runAsGroup: 1000
    fsGroup: 1000

  # Service configuration
  service:
    enabled: true
    type: ClusterIP
    port: 8200
    targetPort: 8200

  # Storage configuration
  dataStorage:
    enabled: true
    size: 10Gi
    storageClass: "vault-storage"  # เปลี่ยนตาม storage class ที่มี
    accessMode: ReadWriteOnce

  # Audit storage
  auditStorage:
    enabled: true
    size: 10Gi
    storageClass: "vault-storage"
    accessMode: ReadWriteOnce

  # High Availability configuration
  ha:
    enabled: true
    replicas: 3
    raft:
      enabled: true
      setNodeId: true
      config: |
        ui = true
        
        listener "tcp" {
          tls_disable = 0
          address = "[::]:8200"
          cluster_address = "[::]:8201"
          tls_cert_file = "/vault/tls/tls.crt"
          tls_key_file  = "/vault/tls/tls.key"
          tls_client_ca_file = "/vault/tls/ca.crt"
        }

        storage "raft" {
          path = "/vault/data"
          
          retry_join {
            leader_api_addr = "https://vault-0.vault-internal:8200"
            leader_ca_cert_file = "/vault/tls/ca.crt"
            leader_client_cert_file = "/vault/tls/tls.crt"
            leader_client_key_file = "/vault/tls/tls.key"
          }
          
          retry_join {
            leader_api_addr = "https://vault-1.vault-internal:8200"
            leader_ca_cert_file = "/vault/tls/ca.crt"
            leader_client_cert_file = "/vault/tls/tls.crt"
            leader_client_key_file = "/vault/tls/tls.key"
          }
          
          retry_join {
            leader_api_addr = "https://vault-2.vault-internal:8200"
            leader_ca_cert_file = "/vault/tls/ca.crt"
            leader_client_cert_file = "/vault/tls/tls.crt"
            leader_client_key_file = "/vault/tls/tls.key"
          }
        }

        service_registration "kubernetes" {}

        seal "transit" {
          address = "https://vault-transit.vault.svc.cluster.local:8200"
          disable_renewal = "false"
          key_name = "autounseal"
          mount_path = "transit/"
          tls_ca_cert = "/vault/tls/ca.crt"
        }

  # Standalone mode (for single instance testing)
  standalone:
    enabled: false

  # UI configuration
  ui:
    enabled: true
    serviceType: "ClusterIP"

# UI service
ui:
  enabled: true
  serviceType: ClusterIP
  externalPort: 8200

# Server extra environment variables
serverExtraEnvironmentVars:
  VAULT_SKIP_VERIFY: "false"
  VAULT_LOG_LEVEL: "info"
  VAULT_API_ADDR: "https://vault.domain.app"
  VAULT_CLUSTER_ADDR: "https://$(HOSTNAME).vault-internal:8201"
```

### 2.3 Install Vault with Helm

```bash
# Install Vault
helm install vault hashicorp/vault \
  --namespace vault \
  --values vault-values.yaml

# ตรวจสอบการติดตั้ง
kubectl get pods -n vault
kubectl get pvc -n vault
kubectl get svc -n vault

# ดู logs
kubectl logs vault-0 -n vault
```

**Expected Output:**
```
NAME      READY   STATUS    RESTARTS   AGE
vault-0   0/1     Running   0          1m
vault-1   0/1     Running   0          1m
vault-2   0/1     Running   0          1m
```

**Note:** Pods จะไม่ READY จนกว่าจะ initialize และ unseal Vault

---

## Part 3: Vault Initialization & Unsealing

### 3.1 Initialize Vault

```bash
# Initialize Vault (ทำกับ pod แรกเท่านั้น)
kubectl exec -n vault vault-0 -- vault operator init \
  -key-shares=5 \
  -key-threshold=3 \
  -format=json > vault-init-keys.json

# ⚠️ IMPORTANT: บันทึกไฟล์นี้ในที่ปลอดภัย!
# ไฟล์นี้มี unseal keys และ root token

# ดูเนื้อหา
cat vault-init-keys.json | jq

# แยก unseal keys และ root token
cat vault-init-keys.json | jq -r '.unseal_keys_b64[]' > unseal-keys.txt
cat vault-init-keys.json | jq -r '.root_token' > root-token.txt

echo "Unseal Keys:"
cat unseal-keys.txt

echo "Root Token:"
cat root-token.txt
```

### 3.2 Unseal Vault Pods

```bash
# Unseal vault-0
UNSEAL_KEY_1=$(cat vault-init-keys.json | jq -r '.unseal_keys_b64[0]')
UNSEAL_KEY_2=$(cat vault-init-keys.json | jq -r '.unseal_keys_b64[1]')
UNSEAL_KEY_3=$(cat vault-init-keys.json | jq -r '.unseal_keys_b64[2]')

# Unseal vault-0
kubectl exec -n vault vault-0 -- vault operator unseal $UNSEAL_KEY_1
kubectl exec -n vault vault-0 -- vault operator unseal $UNSEAL_KEY_2
kubectl exec -n vault vault-0 -- vault operator unseal $UNSEAL_KEY_3

# Unseal vault-1
kubectl exec -n vault vault-1 -- vault operator raft join https://vault-0.vault-internal:8200
kubectl exec -n vault vault-1 -- vault operator unseal $UNSEAL_KEY_1
kubectl exec -n vault vault-1 -- vault operator unseal $UNSEAL_KEY_2
kubectl exec -n vault vault-1 -- vault operator unseal $UNSEAL_KEY_3

# Unseal vault-2
kubectl exec -n vault vault-2 -- vault operator raft join https://vault-0.vault-internal:8200
kubectl exec -n vault vault-2 -- vault operator unseal $UNSEAL_KEY_1
kubectl exec -n vault vault-2 -- vault operator unseal $UNSEAL_KEY_2
kubectl exec -n vault vault-2 -- vault operator unseal $UNSEAL_KEY_3

# ตรวจสอบสถานะ
kubectl exec -n vault vault-0 -- vault status
kubectl exec -n vault vault-1 -- vault status
kubectl exec -n vault vault-2 -- vault status
```

### 3.3 Verify High Availability

```bash
# ตรวจสอบ raft peers
kubectl exec -n vault vault-0 -- vault operator raft list-peers

# Expected output:
# Node       Address                        State       Voter
# ----       -------                        -----       -----
# vault-0    vault-0.vault-internal:8201    leader      true
# vault-1    vault-1.vault-internal:8201    follower    true
# vault-2    vault-2.vault-internal:8201    follower    true
```

---

## Part 4: Domain Exposure & Ingress Setup

### 4.1 Create TLS Certificate Secret

#### Option A: Self-Signed Certificate (Development)

```bash
# สร้าง self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout vault-tls.key \
  -out vault-tls.crt \
  -subj "/CN=vault.domain.app/O=vault.domain.app" \
  -addext "subjectAltName=DNS:vault.domain.app,DNS:*.vault.domain.app"

# สร้าง Kubernetes secret
kubectl create secret tls vault-tls \
  --cert=vault-tls.crt \
  --key=vault-tls.key \
  -n vault
```

#### Option B: Let's Encrypt with Cert-Manager (Production)

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# ตรวจสอบการติดตั้ง
kubectl get pods -n cert-manager

# สร้าง ClusterIssuer สำหรับ Let's Encrypt
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@domain.app
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

#### Option C: Cloudflare Origin Certificate (Recommended for Cloudflare)

```bash
# สร้าง certificate ใน Cloudflare Dashboard:
# 1. ไปที่ SSL/TLS > Origin Server
# 2. Create Certificate
# 3. เลือก Private key type: RSA(2048)
# 4. Hostnames: vault.domain.app, *.domain.app
# 5. Certificate Validity: 15 years
# 6. Create

# บันทึก certificate และ private key
cat > vault-cloudflare.crt <<'EOF'
-----BEGIN CERTIFICATE-----
<paste certificate here>
-----END CERTIFICATE-----
EOF

cat > vault-cloudflare.key <<'EOF'
-----BEGIN PRIVATE KEY-----
<paste private key here>
-----END PRIVATE KEY-----
EOF

# สร้าง secret
kubectl create secret tls vault-tls \
  --cert=vault-cloudflare.crt \
  --key=vault-cloudflare.key \
  -n vault

# ตรวจสอบ
kubectl get secret vault-tls -n vault
```

### 4.2 Create Ingress Resource

```bash
# สร้าง Ingress
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: vault-ingress
  namespace: vault
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    nginx.ingress.kubernetes.io/ssl-passthrough: "false"
    # cert-manager annotations (ถ้าใช้ Let's Encrypt)
    # cert-manager.io/cluster-issuer: "letsencrypt-prod"
    # Increase timeout for Vault operations
    nginx.ingress.kubernetes.io/proxy-connect-timeout: "300"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "300"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "300"
spec:
  tls:
  - hosts:
    - vault.domain.app
    secretName: vault-tls
  rules:
  - host: vault.domain.app
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: vault
            port:
              number: 8200
EOF

# ตรวจสอบ Ingress
kubectl get ingress -n vault
kubectl describe ingress vault-ingress -n vault
```

### 4.3 Test Access

```bash
# Test HTTPS access
curl -k https://vault.domain.app/v1/sys/health

# Expected output (JSON):
# {
#   "initialized": true,
#   "sealed": false,
#   "standby": false,
#   "performance_standby": false,
#   "replication_performance_mode": "disabled",
#   "replication_dr_mode": "disabled",
#   "server_time_utc": ...,
#   "version": "1.18.0",
#   "cluster_name": "vault-cluster-...",
#   "cluster_id": "..."
# }

# Test UI access
echo "Open browser: https://vault.domain.app/ui/"
```

---

## Part 5: TLS/SSL Certificate Setup

### 5.1 Configure Vault Internal TLS

```bash
# สร้าง CA certificate สำหรับ internal communication
openssl genrsa -out ca.key 2048
openssl req -x509 -new -nodes -key ca.key -sha256 -days 3650 \
  -out ca.crt \
  -subj "/CN=Vault CA/O=Vault CA"

# สร้าง certificate สำหรับ Vault pods
cat > vault-csr.conf <<EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = v3_req

[dn]
CN = vault.vault.svc.cluster.local
O = Vault

[v3_req]
subjectAltName = @alt_names

[alt_names]
DNS.1 = vault
DNS.2 = vault.vault
DNS.3 = vault.vault.svc
DNS.4 = vault.vault.svc.cluster.local
DNS.5 = vault-0.vault-internal
DNS.6 = vault-1.vault-internal
DNS.7 = vault-2.vault-internal
DNS.8 = vault-0.vault-internal.vault.svc.cluster.local
DNS.9 = vault-1.vault-internal.vault.svc.cluster.local
DNS.10 = vault-2.vault-internal.vault.svc.cluster.local
DNS.11 = localhost
IP.1 = 127.0.0.1
EOF

# สร้าง private key และ CSR
openssl req -new -nodes \
  -out vault.csr \
  -newkey rsa:2048 \
  -keyout vault.key \
  -config vault-csr.conf

# Sign certificate with CA
openssl x509 -req \
  -in vault.csr \
  -CA ca.crt \
  -CAkey ca.key \
  -CAcreateserial \
  -out vault.crt \
  -days 365 \
  -extensions v3_req \
  -extfile vault-csr.conf

# สร้าง Kubernetes secret สำหรับ internal TLS
kubectl create secret generic vault-tls-internal \
  --from-file=tls.crt=vault.crt \
  --from-file=tls.key=vault.key \
  --from-file=ca.crt=ca.crt \
  -n vault

# ตรวจสอบ
kubectl get secret vault-tls-internal -n vault
```

### 5.2 Update Vault Configuration to Use TLS

อัพเดท `vault-values.yaml`:

```yaml
server:
  extraVolumes:
    - type: secret
      name: vault-tls-internal
      path: /vault/tls
```

แล้ว upgrade Helm release:

```bash
helm upgrade vault hashicorp/vault \
  --namespace vault \
  --values vault-values.yaml
```

---

## Part 6: High Availability Configuration

### 6.1 Verify HA Status

```bash
# ตรวจสอบ leader
kubectl exec -n vault vault-0 -- vault status | grep "HA Enabled"

# ตรวจสอบ raft cluster
kubectl exec -n vault vault-0 -- vault operator raft list-peers

# ตรวจสอบ cluster members
for i in 0 1 2; do
  echo "=== vault-$i ==="
  kubectl exec -n vault vault-$i -- vault status | grep -E "HA Enabled|HA Mode"
done
```

### 6.2 Test Failover

```bash
# หา active node
LEADER=$(kubectl exec -n vault vault-0 -- vault status | grep "HA Mode" | awk '{print $3}')
echo "Current leader: $LEADER"

# Delete leader pod เพื่อทดสอบ failover
kubectl delete pod vault-0 -n vault

# รอ pod ขึ้นใหม่
kubectl wait --for=condition=ready pod/vault-0 -n vault --timeout=300s

# Unseal pod ใหม่
kubectl exec -n vault vault-0 -- vault operator unseal $UNSEAL_KEY_1
kubectl exec -n vault vault-0 -- vault operator unseal $UNSEAL_KEY_2
kubectl exec -n vault vault-0 -- vault operator unseal $UNSEAL_KEY_3

# ตรวจสอบ leader ใหม่
kubectl exec -n vault vault-1 -- vault operator raft list-peers
```

---

## Part 7: Backup & Disaster Recovery

### 7.1 Create Backup Script

```bash
# สร้าง backup script
cat > vault-backup.sh <<'EOF'
#!/bin/bash
set -e

NAMESPACE="vault"
BACKUP_DIR="/backup/vault"
DATE=$(date +%Y%m%d_%H%M%S)
VAULT_ADDR="https://vault.domain.app"
VAULT_TOKEN="${VAULT_TOKEN}"

mkdir -p ${BACKUP_DIR}

# Backup Raft snapshot
echo "Creating Raft snapshot..."
kubectl exec -n ${NAMESPACE} vault-0 -- vault operator raft snapshot save /tmp/vault-snapshot-${DATE}.snap

# Copy snapshot from pod
kubectl cp ${NAMESPACE}/vault-0:/tmp/vault-snapshot-${DATE}.snap ${BACKUP_DIR}/vault-snapshot-${DATE}.snap

# Backup secrets (optional)
echo "Backing up KV secrets..."
vault kv list -format=json secret/ > ${BACKUP_DIR}/kv-list-${DATE}.json

# Backup policies
echo "Backing up policies..."
vault policy list -format=json > ${BACKUP_DIR}/policies-${DATE}.json

# Backup auth methods
echo "Backing up auth methods..."
vault auth list -format=json > ${BACKUP_DIR}/auth-methods-${DATE}.json

# Compress backup
tar -czf ${BACKUP_DIR}/vault-backup-${DATE}.tar.gz \
  ${BACKUP_DIR}/vault-snapshot-${DATE}.snap \
  ${BACKUP_DIR}/kv-list-${DATE}.json \
  ${BACKUP_DIR}/policies-${DATE}.json \
  ${BACKUP_DIR}/auth-methods-${DATE}.json

# Remove temporary files
rm -f ${BACKUP_DIR}/vault-snapshot-${DATE}.snap \
      ${BACKUP_DIR}/kv-list-${DATE}.json \
      ${BACKUP_DIR}/policies-${DATE}.json \
      ${BACKUP_DIR}/auth-methods-${DATE}.json

# Keep only last 30 days backups
find ${BACKUP_DIR} -name "vault-backup-*.tar.gz" -mtime +30 -delete

echo "Backup completed: ${BACKUP_DIR}/vault-backup-${DATE}.tar.gz"
EOF

chmod +x vault-backup.sh
```

### 7.2 Schedule Automated Backups

```bash
# สร้าง CronJob สำหรับ backup
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: CronJob
metadata:
  name: vault-backup
  namespace: vault
spec:
  schedule: "0 2 * * *"  # ทุกวันเวลา 02:00
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: vault
          containers:
          - name: backup
            image: hashicorp/vault:1.18.0
            command:
            - /bin/sh
            - -c
            - |
              vault operator raft snapshot save /backup/vault-snapshot-\$(date +%Y%m%d_%H%M%S).snap
            env:
            - name: VAULT_ADDR
              value: "https://vault:8200"
            - name: VAULT_SKIP_VERIFY
              value: "true"
            volumeMounts:
            - name: backup
              mountPath: /backup
          volumes:
          - name: backup
            persistentVolumeClaim:
              claimName: vault-backup-pvc
          restartPolicy: OnFailure
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: vault-backup-pvc
  namespace: vault
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 50Gi
  storageClassName: vault-storage
EOF
```

### 7.3 Restore from Backup

```bash
# Restore Raft snapshot
kubectl cp vault-backup-20251124.snap vault/vault-0:/tmp/vault-backup.snap

kubectl exec -n vault vault-0 -- vault operator raft snapshot restore \
  -force /tmp/vault-backup.snap
```

---

## Part 8: Security Hardening

### 8.1 Enable Audit Logging

```bash
# Login to Vault
export VAULT_ADDR="https://vault.domain.app"
export VAULT_TOKEN="<root-token>"

# Enable file audit
kubectl exec -n vault vault-0 -- vault audit enable file \
  file_path=/vault/audit/audit.log

# ตรวจสอบ audit devices
kubectl exec -n vault vault-0 -- vault audit list
```

### 8.2 Create Admin Policy

```bash
# สร้าง admin policy
cat > admin-policy.hcl <<EOF
# Full access to all paths
path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
EOF

vault policy write admin admin-policy.hcl

# สร้าง admin user
vault auth enable userpass

vault write auth/userpass/users/admin \
  password="<strong-password>" \
  policies="admin"
```

### 8.3 Rotate Root Token

```bash
# Generate new root token
vault operator generate-root -init

# Follow the prompts to rotate root token

# Revoke old root token (after generating new one)
vault token revoke <old-root-token>
```

### 8.4 Enable Network Policies

```bash
# สร้าง NetworkPolicy
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: vault-network-policy
  namespace: vault
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: vault
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 8200
    - protocol: TCP
      port: 8201
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 8200
    - protocol: TCP
      port: 8201
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
EOF
```

---

## Part 9: Monitoring & Logging

### 9.1 Enable Prometheus Metrics

```bash
# Update vault-values.yaml
cat >> vault-values.yaml <<EOF

serverTelemetry:
  prometheusRules:
    enabled: true
  serviceMonitor:
    enabled: true
EOF

# Upgrade Helm release
helm upgrade vault hashicorp/vault \
  --namespace vault \
  --values vault-values.yaml
```

### 9.2 Install Prometheus (if not installed)

```bash
# เพิ่ม Prometheus Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace

# ตรวจสอบ
kubectl get pods -n monitoring
```

### 9.3 Create Grafana Dashboard

```bash
# Get Grafana password
kubectl get secret -n monitoring prometheus-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode
echo

# Port-forward Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Open browser: http://localhost:3000
# Username: admin
# Password: <from above>

# Import Vault dashboard ID: 12904
```

### 9.4 Configure Logging

```bash
# Install Loki for log aggregation
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm install loki grafana/loki-stack \
  --namespace monitoring \
  --set grafana.enabled=false \
  --set prometheus.enabled=false

# Configure Promtail to collect Vault logs
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: promtail-vault-config
  namespace: monitoring
data:
  promtail.yaml: |
    server:
      http_listen_port: 9080
    clients:
      - url: http://loki:3100/loki/api/v1/push
    scrape_configs:
      - job_name: vault
        kubernetes_sd_configs:
          - role: pod
            namespaces:
              names:
                - vault
        relabel_configs:
          - source_labels: [__meta_kubernetes_pod_label_app_kubernetes_io_name]
            regex: vault
            action: keep
EOF
```

---

## Part 10: Application Integration

### 10.1 Enable Kubernetes Auth

```bash
export VAULT_ADDR="https://vault.domain.app"
export VAULT_TOKEN="<root-token>"

# Enable Kubernetes auth
vault auth enable kubernetes

# Configure Kubernetes auth
kubectl exec -n vault vault-0 -- sh -c '
  KUBERNETES_SERVICE_HOST="kubernetes.default.svc"
  KUBERNETES_SERVICE_PORT="443"
  VAULT_SA_NAME=$(kubectl get sa vault -n vault -o jsonpath="{.secrets[*]['name']}")
  SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_NAME -n vault -o jsonpath="{.data.token}" | base64 --decode)
  SA_CA_CRT=$(kubectl get secret $VAULT_SA_NAME -n vault -o jsonpath="{.data['ca\.crt']}" | base64 --decode)
  
  vault write auth/kubernetes/config \
    token_reviewer_jwt="$SA_JWT_TOKEN" \
    kubernetes_host="https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT" \
    kubernetes_ca_cert="$SA_CA_CRT" \
    issuer="https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT"
'
```

### 10.2 Create Application Role

```bash
# สร้าง policy สำหรับ application
vault policy write app-policy - <<EOF
path "secret/data/app/*" {
  capabilities = ["read", "list"]
}
EOF

# สร้าง Kubernetes auth role
vault write auth/kubernetes/role/app-role \
  bound_service_account_names=vault-auth \
  bound_service_account_namespaces=default,production \
  policies=app-policy \
  ttl=24h
```

### 10.3 Test Integration

ดูตัวอย่างใน [VAULT_SETUP_FROM_ZERO.md](./VAULT_SETUP_FROM_ZERO.md) Part 8

---

## Troubleshooting Guide

### Issue: Pods Not Ready

```bash
# ตรวจสอบ pod logs
kubectl logs vault-0 -n vault

# ตรวจสอบ events
kubectl describe pod vault-0 -n vault

# ตรวจสอบ Vault status
kubectl exec -n vault vault-0 -- vault status
```

### Issue: Cannot Access via Domain

```bash
# ตรวจสอบ DNS
nslookup vault.domain.app

# ตรวจสอบ Ingress
kubectl get ingress -n vault
kubectl describe ingress vault-ingress -n vault

# ตรวจสอบ certificate
kubectl get secret vault-tls -n vault
```

### Issue: Sealed Vault After Restart

```bash
# Unseal all pods
for i in 0 1 2; do
  kubectl exec -n vault vault-$i -- vault operator unseal $UNSEAL_KEY_1
  kubectl exec -n vault vault-$i -- vault operator unseal $UNSEAL_KEY_2
  kubectl exec -n vault vault-$i -- vault operator unseal $UNSEAL_KEY_3
done
```

### Issue: Raft Cluster Issues

```bash
# ตรวจสอบ raft peers
kubectl exec -n vault vault-0 -- vault operator raft list-peers

# Remove failed peer
kubectl exec -n vault vault-0 -- vault operator raft remove-peer <peer-id>

# Re-join cluster
kubectl exec -n vault vault-1 -- vault operator raft join https://vault-0.vault-internal:8200
```

---

## Production Checklist

### Pre-Production

- [ ] TLS certificates configured (Let's Encrypt or custom)
- [ ] DNS records created and verified
- [ ] Storage class configured with appropriate performance
- [ ] Resource limits set appropriately
- [ ] High Availability tested (3+ replicas)
- [ ] Backup strategy implemented
- [ ] Disaster recovery plan documented

### Security

- [ ] TLS enabled for all communication
- [ ] Root token rotated
- [ ] Admin policies created
- [ ] Audit logging enabled
- [ ] Network policies configured
- [ ] Secrets encryption at rest
- [ ] Auto-unseal configured (Cloud KMS)

### Monitoring

- [ ] Prometheus metrics enabled
- [ ] Grafana dashboards configured
- [ ] Log aggregation setup (Loki/ELK)
- [ ] Alerting rules configured
- [ ] Health checks configured

### Operations

- [ ] Automated backups scheduled
- [ ] Restore procedure tested
- [ ] Failover procedure tested
- [ ] Upgrade procedure documented
- [ ] Access control documented
- [ ] Runbooks created

### Application Integration

- [ ] Kubernetes auth configured
- [ ] Application policies created
- [ ] Application roles created
- [ ] Secrets Store CSI Driver installed
- [ ] Sample applications tested

---

## Quick Reference Commands

```bash
# Check Vault status
kubectl exec -n vault vault-0 -- vault status

# List Raft peers
kubectl exec -n vault vault-0 -- vault operator raft list-peers

# Unseal Vault
kubectl exec -n vault vault-0 -- vault operator unseal <key>

# Login
vault login -address=https://vault.domain.app <token>

# Create secret
vault kv put secret/myapp password=secret123

# Read secret
vault kv get secret/myapp

# Enable audit
vault audit enable file file_path=/vault/audit/audit.log

# Backup
kubectl exec -n vault vault-0 -- vault operator raft snapshot save /tmp/backup.snap

# Restore
kubectl exec -n vault vault-0 -- vault operator raft snapshot restore /tmp/backup.snap
```

---

## Additional Resources

- **Official Documentation:** https://developer.hashicorp.com/vault
- **Helm Chart:** https://github.com/hashicorp/vault-helm
- **Best Practices:** https://learn.hashicorp.com/vault
- **Community:** https://discuss.hashicorp.com/c/vault

---

**Version:** 1.0  
**Last Updated:** 24 พฤศจิกายน 2025  
**Maintainer:** DevSecOps Team  
**License:** Internal Use Only
