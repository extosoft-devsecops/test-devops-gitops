# 🚀 Codefresh GitOps Testing Guide

## Overview
การทดสอบ Helm chart พร้อม Vault integration ผ่าน Codefresh ArgoCD

## Prerequisites Completed ✅

### 1. HashiCorp Vault Setup
- **Vault URL**: `https://vault-devops.extosoft.app`
- **Secrets Created**:
  - `secret/k8s/test-devops-develop` (version 5)
  - `secret/k8s/test-devops-uat` (version 3)

### 2. Kubernetes CSI Driver Installation
```bash
# Secrets Store CSI Driver v1.4.0
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/secrets-store-csi-driver/v1.4.0/deploy/secrets-store-csi-driver.yaml

# Vault CSI Provider v1.4.1
kubectl apply -f https://raw.githubusercontent.com/hashicorp/vault-csi-provider/v1.4.1/deployment/vault-csi-provider.yaml
```

### 3. ServiceAccount for Vault Authentication
```bash
kubectl create serviceaccount vault-auth -n gke-nonprod-test-devops-develop
kubectl create serviceaccount vault-auth -n gke-nonprod-test-devops-uat
```

## ArgoCD Applications Ready for Testing

### 1. Development Environment
- **File**: `git-sources/codefresh/default/test-devops-develop.yaml`
- **Namespace**: `gke-nonprod-test-devops-develop`
- **Values File**: `values-develop.yaml`
- **Vault Path**: `secret/data/k8s/test-devops-develop`

### 2. UAT Environment  
- **File**: `git-sources/codefresh/default/test-devops-uat.yaml`
- **Namespace**: `gke-nonprod-test-devops-uat`
- **Values File**: `values-uat.yaml`
- **Vault Path**: `secret/data/k8s/test-devops-uat`

### 3. Production Environment
- **File**: `git-sources/codefresh/default/test-devops-prod.yaml`
- **Cluster**: `gke-test-devops-479012-asia-southeast1-a-gke-prod`
- **Namespace**: `gke-prod-test-devops`
- **Values File**: `values-prod-gke.yaml`

## Expected Kubernetes Resources

เมื่อ deploy สำเร็จ จะได้ resources ทั้งหมด 10 ชิ้น:

1. **ServiceAccount** - `test-devops-test-devops-app`
2. **Secret** - `test-devops-test-devops-app-datadog-secret` (placeholder)
3. **ClusterRole** - `test-devops-test-devops-app-datadog-cr`
4. **ClusterRoleBinding** - `test-devops-test-devops-app-datadog-crb`
5. **Secret** - `app-secrets` (จาก Vault via SecretProviderClass)
6. **SecretProviderClass** - `vault-datadog-secret`
7. **Service** - `test-devops-test-devops-app`
8. **Deployment** - `test-devops-test-devops-app`
9. **DaemonSet** - `test-devops-test-devops-app-datadog`
10. **PodDisruptionBudget** - `test-devops-test-devops-app` (UAT/Prod only)

## Environment Variables Injected from Vault

```bash
DD_API_KEY=<from_vault>
DD_SITE=<from_vault>
DD_ENV=<from_vault>
DD_HOSTNAME=<from_vault>
APP_NAME=<from_vault>
NODE_ENV=<from_vault>
SERVICE_NAME=<from_vault>
PORT=<from_vault>
ENABLE_METRICS=<from_vault>
```

## Testing Steps in Codefresh

### 1. Deploy Development Environment
```bash
# ArgoCD จะ sync จาก git-sources/codefresh/default/test-devops-develop.yaml
# ใช้ helm/app/values-develop.yaml
# Deploy ไปยัง namespace: gke-nonprod-test-devops-develop
```

### 2. Verify Vault Secret Injection
```bash
kubectl get secretproviderclass -n gke-nonprod-test-devops-develop
kubectl get secret app-secrets -n gke-nonprod-test-devops-develop -o yaml
kubectl describe pod <pod-name> -n gke-nonprod-test-devops-develop
```

### 3. Check Application Health
```bash
kubectl get pods -n gke-nonprod-test-devops-develop
kubectl logs -f deployment/test-devops-test-devops-app -n gke-nonprod-test-devops-develop
```

### 4. Test Datadog Integration
- ตรวจสอบ metrics ใน Datadog dashboard
- Verify APM traces
- Check infrastructure monitoring

## Troubleshooting

### Common Issues:
1. **SecretProviderClass not found** → CSI driver ยังไม่ได้ install
2. **Vault authentication failed** → ServiceAccount `vault-auth` ไม่มี
3. **Pod stuck in pending** → Resources/NodeSelector issues
4. **Environment variables empty** → Vault path หรือ field name ผิด

### Debug Commands:
```bash
# Check CSI driver pods
kubectl get pods -n kube-system | grep secrets-store
kubectl get pods -n csi | grep vault

# Check Vault secrets
kubectl get secret app-secrets -o jsonpath='{.data}' | base64 -d

# Check SecretProviderClass
kubectl describe secretproviderclass vault-datadog-secret
```

## Success Criteria ✅

- [ ] ArgoCD sync สำเร็จ (healthy/synced)
- [ ] ทุก Pods running และ ready
- [ ] Environment variables ได้รับค่าจาก Vault
- [ ] Datadog agent เชื่อมต่อสำเร็จ
- [ ] Application health checks passed
- [ ] Metrics และ logs ปรากฏใน monitoring systems

## Next Steps

1. **Test in Development** → Deploy ผ่าน Codefresh
2. **Validate UAT** → Promote to UAT environment  
3. **Production Ready** → Final production deployment
4. **Monitor & Alert** → Setup Datadog alerts and dashboards

---
**สถานะ**: ✅ Ready for Codefresh testing
**อัปเดตล่าสุด**: วันที่ 24 พฤศจิกายน 2024