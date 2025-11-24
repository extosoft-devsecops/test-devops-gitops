# การแก้ไขปัญหา SecretProviderClass CRD

## 🔍 **ปัญหาที่พบ:**
```
The Kubernetes API could not find secrets-store.csi.x-k8s.io/SecretProviderClass
Make sure the "SecretProviderClass" CRD is installed on the destination cluster.
```

## ✅ **การแก้ไขที่ดำเนินการ:**

### 1. **ติดตั้ง Secrets Store CSI Driver**
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/secrets-store-csi-driver/v1.4.0/deploy/secrets-store-csi-driver.yaml
```

### 2. **ติดตั้ง HashiCorp Vault CSI Provider**
```bash
kubectl apply -f https://raw.githubusercontent.com/hashicorp/vault-csi-provider/v1.4.1/deployment/vault-csi-provider.yaml
```

### 3. **สร้าง ServiceAccount ที่จำเป็น**
```bash
kubectl create serviceaccount secrets-store-csi-driver -n kube-system
```

### 4. **ติดตั้ง SecretProviderClass CRD**
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/secrets-store-csi-driver/v1.4.0/deploy/secrets-store.csi.x-k8s.io_secretproviderclasses.yaml
```

### 5. **สร้าง ServiceAccount สำหรับ Vault Authentication**
```bash
kubectl create serviceaccount vault-auth -n gke-nonprod-test-devops-uat
kubectl create serviceaccount vault-auth -n gke-nonprod-test-devops-develop
```

## 📋 **ผลการตรวจสอบ:**

### ✅ **CRDs ที่ติดตั้งแล้ว:**
```bash
kubectl get crd | grep secrets-store
# secretproviderclasses.secrets-store.csi.x-k8s.io       2025-11-24T06:44:14Z
```

### ✅ **Pods ที่ทำงานอยู่:**
```bash
# Secrets Store CSI Driver
kubectl get pods -n kube-system | grep csi-secrets
# csi-secrets-store-* pods running in kube-system

# Vault CSI Provider  
kubectl get pods -n csi
# vault-csi-provider-* pods running in csi namespace
```

### ✅ **ServiceAccounts ที่สร้างแล้ว:**
```bash
kubectl get serviceaccount vault-auth -n gke-nonprod-test-devops-uat
kubectl get serviceaccount vault-auth -n gke-nonprod-test-devops-develop
```

## 🚀 **ตอนนี้สามารถ Deploy ได้แล้ว:**

```bash
# ใน UAT namespace
helm upgrade --install test-devops-uat ./app \
  -f values-uat.yaml \
  --namespace gke-nonprod-test-devops-uat

# ใน Develop namespace  
helm upgrade --install test-devops-develop ./app \
  -f values-develop.yaml \
  --namespace gke-nonprod-test-devops-develop
```

## 📝 **หมายเหตุสำคัญ:**

1. **Vault Authentication**: ยังต้องตั้งค่า Vault Kubernetes auth method และ policies
2. **Secrets**: ยังต้องสร้าง secrets ใน Vault ตาม path ที่กำหนด
3. **Network**: ตรวจสอบว่า pods สามารถเข้าถึง Vault server ได้

## 🔧 **คำสั่งตรวจสอบระบบ:**

```bash
# ตรวจสอบ CSI Driver pods
kubectl get pods -n kube-system | grep -E "(csi-secrets|vault)"

# ตรวจสอบ CRDs
kubectl get crd | grep secrets-store

# ตรวจสอบ SecretProviderClass
kubectl get secretproviderclass -A

# ตรวจสอบ ServiceAccount
kubectl get serviceaccount vault-auth -A
```

✅ **ปัญหา SecretProviderClass CRD ได้รับการแก้ไขเรียบร้อยแล้ว!**