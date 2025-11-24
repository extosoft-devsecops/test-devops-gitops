# Datadog Vault Integration Guide

## Overview
การ integration นี้ช่วยให้คุณสามารถจัดการ Datadog API Key ผ่าน HashiCorp Vault แทนการเก็บใน Kubernetes Secrets โดยตรง

## Prerequisites
1. HashiCorp Vault ที่ทำงานอยู่
2. Vault CSI Driver ติดตั้งใน Kubernetes cluster
3. ServiceAccount `vault-auth` ที่มีสิทธิ์เข้าถึง Vault
4. Vault policy ที่อนุญาตให้อ่าน secret paths

## Setup Process

### 1. Setup Datadog API Key in Vault

```bash
# ใช้สคริปต์ที่เตรียมไว้
./setup-datadog-vault-secrets.sh <VAULT_TOKEN> <DATADOG_API_KEY>

# หรือสร้างด้วยตนเอง
export VAULT_ADDR="https://vault-devops.extosoft.app"
export VAULT_TOKEN="your-vault-token"

# Development
vault kv put secret/k8s/test-devops-develop datadog_api_key="your-api-key"

# UAT
vault kv put secret/k8s/test-devops-uat datadog_api_key="your-api-key"

# Production GKE
vault kv put secret/k8s/test-devops-prod-gke datadog_api_key="your-api-key"
```

### 2. Deploy with Vault Integration

```bash
# Development
helm upgrade --install test-devops-develop ./app \
  -f values-develop.yaml \
  --namespace test-devops-develop

# UAT
helm upgrade --install test-devops-uat ./app \
  -f values-uat.yaml \
  --namespace test-devops-uat

# Production
helm upgrade --install test-devops-prod ./app \
  -f values-prod-gke.yaml \
  --namespace test-devops-prod
```

## Vault Secret Paths

| Environment | Vault Path | Field Name |
|-------------|------------|------------|
| Development | `secret/data/k8s/test-devops-develop` | `datadog_api_key` |
| UAT | `secret/data/k8s/test-devops-uat` | `datadog_api_key` |
| Production GKE | `secret/data/k8s/test-devops-prod-gke` | `datadog_api_key` |
| Production EKS | `secret/data/k8s/test-devops-prod-eks` | `datadog_api_key` |

## Configuration Files

### Values Files Updated
- `values-develop.yaml` - ✅ Vault integration enabled
- `values-uat.yaml` - ✅ Vault integration enabled  
- `values-prod-gke.yaml` - ✅ Vault integration enabled

### New Template Files
- `vault-datadog-secretprovider.yaml` - SecretProviderClass for Vault CSI
- Updated `datadog-daemonset.yaml` - Added Vault volume mounts

## Key Features

1. **Automatic Secret Retrieval**: Datadog Agent pods automatically retrieve API key from Vault
2. **Environment-Specific Paths**: Each environment has its own secret path in Vault
3. **Secure**: API keys never stored in Git or Kubernetes manifests
4. **Centralized Management**: All secrets managed through Vault UI/CLI

## Verification

### Check SecretProviderClass
```bash
kubectl get secretproviderclass vault-datadog-secret -n <namespace>
```

### Check Vault CSI Pods
```bash
kubectl get pods -n kube-system | grep secrets-store
```

### Check Datadog Agent Logs
```bash
kubectl logs -l app=datadog-agent -n <namespace>
```

### Verify Secret Creation
```bash
kubectl get secrets datadog-api-key -n <namespace>
```

## Troubleshooting

### Common Issues

1. **SecretProviderClass not found**
   - ตรวจสอบว่า Vault CSI Driver ติดตั้งแล้ว
   - ตรวจสอบ namespace ที่ถูกต้อง

2. **Secret not created**
   - ตรวจสอบ ServiceAccount permissions
   - ตรวจสอบ Vault policy
   - ตรวจสอบ secret path ใน Vault

3. **Datadog Agent startup issues**
   - ตรวจสอบ API key ใน secret
   - ตรวจสอบ volume mounts
   - ตรวจสอบ environment variables

### Debug Commands

```bash
# Check Vault connection
kubectl exec -it <datadog-pod> -- vault auth -method=kubernetes

# Check secret mount
kubectl exec -it <datadog-pod> -- ls -la /mnt/secrets-store/

# Check environment variables
kubectl exec -it <datadog-pod> -- env | grep DD_
```

## Security Notes

1. Vault tokens ควรมี TTL ที่เหมาะสม
2. ServiceAccount ควรมีสิทธิ์เฉพาะที่จำเป็น
3. Secret rotation ควรทำตามกำหนดเวลา
4. Monitor Vault audit logs สำหรับการเข้าถึง secrets

## References
- [Vault CSI Driver Documentation](https://github.com/hashicorp/vault-csi-provider)
- [Datadog Agent Configuration](https://docs.datadoghq.com/agent/kubernetes/)
- [Kubernetes Secret Store CSI Driver](https://secrets-store-csi-driver.sigs.k8s.io/)