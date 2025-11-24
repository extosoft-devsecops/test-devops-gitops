# Required Secrets for test-devops Application

## 🔐 **Secrets ที่ต้องการ (Required Secrets)**

### 1. **Datadog Secrets**
```bash
# ใน Vault path: secret/data/k8s/test-devops-develop
{
  "DD_API_KEY": "your-datadog-api-key-here",
  "DD_SITE": "datadoghq.com",
  "DD_ENV": "develop",
  "DD_HOSTNAME": "test-devops-develop"
}
```

### 2. **Application Secrets** 
```bash
# ใน Vault path: secret/data/k8s/test-devops-develop
{
  "APP_NAME": "test-devops-develop",
  "NODE_ENV": "develop",
  "SERVICE_NAME": "test-devops",
  "PORT": "3000",
  "ENABLE_METRICS": "true"
}
```

### 3. **Combined Vault Structure**
```bash
# Complete structure for development environment
vault kv put secret/k8s/test-devops-develop \
  DD_API_KEY="your-datadog-api-key" \
  DD_SITE="datadoghq.com" \
  DD_ENV="develop" \
  DD_HOSTNAME="test-devops-develop" \
  APP_NAME="test-devops-develop" \
  NODE_ENV="develop" \
  SERVICE_NAME="test-devops" \
  PORT="3000" \
  ENABLE_METRICS="true"
```

## 📋 **Environment-Specific Secret Paths**

| Environment | Vault Path | DD_ENV | DD_HOSTNAME |
|-------------|------------|--------|-------------|
| **Development** | `secret/data/k8s/test-devops-develop` | `develop` | `test-devops-develop` |
| **UAT** | `secret/data/k8s/test-devops-uat` | `uat` | `test-devops-uat` |
| **Production GKE** | `secret/data/k8s/test-devops-prod-gke` | `production` | `test-devops-prod-gke` |

## 🔧 **การตั้งค่า Secrets**

### วิธีที่ 1: ใช้ Script ที่เตรียมไว้
```bash
./setup-datadog-vault-secrets.sh <VAULT_TOKEN> <DATADOG_API_KEY>
```

### วิธีที่ 2: Manual Setup
```bash
export VAULT_ADDR="https://vault-devops.extosoft.app"
export VAULT_TOKEN="your-vault-token"

# Development
vault kv put secret/k8s/test-devops-develop \
  DD_API_KEY="your-api-key" \
  DD_SITE="datadoghq.com" \
  DD_ENV="develop" \
  DD_HOSTNAME="test-devops-develop" \
  APP_NAME="test-devops-develop" \
  NODE_ENV="develop" \
  SERVICE_NAME="test-devops" \
  PORT="3000" \
  ENABLE_METRICS="true"
```

## ✅ **การตรวจสอบ (Verification)**

```bash
# ตรวจสอบ secrets ใน Vault
vault kv get secret/k8s/test-devops-develop

# ตรวจสอบ secret ใน Kubernetes
kubectl get secrets app-secrets -n test-devops-develop -o yaml
kubectl describe secretproviderclass vault-datadog-secret -n test-devops-develop
```