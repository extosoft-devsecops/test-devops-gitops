# Vault Kubernetes Authentication Issue - UAT Environment

## วันที่: 24 พฤศจิกายน 2025

## ปัญหาที่พบ

```
MountVolume.SetUp failed for volume "vault-secrets" : rpc error: code = Unknown desc = failed to mount secrets store objects for pod gke-nonprod-test-devops-uat/test-devops-uat-fc7c8c7d9-xj78h, err: rpc error: code = Unknown desc = error making mount request: couldn't read secret "service-name": failed to login: Error making API request.

URL: POST https://vault-devops.extosoft.app/v1/auth/kubernetes/login
Code: 403. Errors:

* permission denied
```

## สาเหตุของปัญหา

### 1. Service Account Configuration ไม่ตรงกัน

**ปัญหา:**
- ไฟล์ `values-uat.yaml` มีการตั้งค่า `vault.serviceAccount: "vault-auth"` แต่ค่านี้ไม่ได้ถูกใช้งานจริง
- Deployment ใช้ service account จาก `serviceAccount.name` ซึ่งไม่ได้ตั้งค่าไว้
- เมื่อ `serviceAccount.name` ไม่ได้กำหนด Helm จะใช้ชื่อ default จาก template: `{{ include "test-devops.fullname" . }}`

**ผลลัพธ์:**
- Pod ใช้ service account ชื่อ `test-devops-uat` (จาก fullname template)
- แต่ Vault role `k8s-app` อนุญาตเฉพาพ: `default`, `vault-auth`, `test-devops-uat`
- แม้ `test-devops-uat` อยู่ในรายการที่อนุญาต แต่ยังมีปัญหาข้อที่ 2

### 2. ขาด ClusterRoleBinding สำหรับ namespace UAT

**ปัญหา:**
- มี ClusterRoleBinding `vault-auth-delegator` แต่ผูกกับ `vault-auth` ใน namespace `default` เท่านั้น
- Service account `vault-auth` ใน namespace `gke-nonprod-test-devops-uat` ไม่มี permission ในการ authenticate กับ Vault

**ClusterRoleBinding ที่มีอยู่:**
```yaml
subjects:
- kind: ServiceAccount
  name: vault-auth
  namespace: default  # ❌ ผูกเฉพาะ default namespace
```

## วิธีแก้ไข

### 1. เพิ่ม Service Account Configuration ใน values-uat.yaml

**ไฟล์:** `/opt/test-devops-gitops/helm/test-devops/values-uat.yaml`

```yaml
# ServiceAccount configuration
serviceAccount:
  create: true
  name: "vault-auth"
```

**อธิบาย:**
- กำหนดให้ deployment ใช้ service account ชื่อ `vault-auth` อย่างชัดเจน
- Service account นี้ต้องมีอยู่แล้วใน namespace หรือจะถูกสร้างโดย Helm

### 2. สร้าง ClusterRoleBinding สำหรับ UAT namespace

```bash
kubectl create clusterrolebinding vault-auth-delegator-uat \
  --clusterrole=system:auth-delegator \
  --serviceaccount=gke-nonprod-test-devops-uat:vault-auth
```

**อธิบาย:**
- ให้ service account `vault-auth` ใน namespace `gke-nonprod-test-devops-uat` มีสิทธิ์ authenticate
- ClusterRole `system:auth-delegator` จำเป็นสำหรับ Kubernetes auth method ของ Vault

### 3. Restart Pods

```bash
kubectl delete pod -n gke-nonprod-test-devops-uat test-devops-uat-58c9445bf7-5dbhs
```

## การตรวจสอบหลังแก้ไข

### ตรวจสอบ Service Account ที่ Deployment ใช้

```bash
kubectl get deployment test-devops-uat -n gke-nonprod-test-devops-uat \
  -o jsonpath='{.spec.template.spec.serviceAccountName}'
```

**ผลลัพธ์:** `vault-auth` ✅

### ตรวจสอบ Pod Status

```bash
kubectl get pods -n gke-nonprod-test-devops-uat
```

**ผลลัพธ์:**
```
NAME                               READY   STATUS    RESTARTS   AGE
test-devops-uat-58c9445bf7-7j6rf   1/1     Running   0          12s
```

**สถานะ:** ✅ Running และ READY 1/1

### ตรวจสอบ Vault Role Configuration

```bash
vault read auth/kubernetes/role/k8s-app
```

**ผลลัพธ์:**
```
bound_service_account_names      [default vault-auth test-devops-uat]
bound_service_account_namespaces [default gke-nonprod-test-devops-develop gke-nonprod-test-devops-uat]
policies                         [k8s-policy]
ttl                             24h
```

**สถานะ:** ✅ Service account และ namespace ถูกต้อง

## เปรียบเทียบกับ Develop Environment

### Develop Environment Configuration

**ไฟล์:** `values-develop.yaml`

```yaml
# ❌ ไม่มีการกำหนด serviceAccount.name
vault:
  enabled: true
  address: "https://vault-devops.extosoft.app"
  skipTLSVerify: "true"
  roleName: "k8s-app"
  serviceAccount: "vault-auth"  # ❌ ค่านี้ไม่ได้ถูกใช้งาน
  secrets:
    secretPath: "secret/data/k8s/test-devops-develop"
```

**Service Account ที่ Deployment ใช้:**
```bash
kubectl get deployment test-devops-develop -n gke-nonprod-test-devops-develop \
  -o jsonpath='{.spec.template.spec.serviceAccountName}'
```
**ผลลัพธ์:** `test-devops-develop`

**สถานะ Develop Pods:**
```
NAME                                   READY   STATUS    RESTARTS   AGE
test-devops-develop-7544754667-4ngk8   1/1     Running   0          3h47m
```

**ClusterRoleBinding:**
- ✅ มี `vault-auth-delegator` สำหรับ `default:vault-auth`
- ❌ ไม่มีสำหรับ `gke-nonprod-test-devops-develop:vault-auth`

**เหตุผลที่ Develop ทำงานได้:**
- Vault role `k8s-app` อนุญาต service account `test-devops-develop` ใน namespace `gke-nonprod-test-devops-develop`
- Develop ใช้ service account ชื่อ `test-devops-develop` (ซึ่งอยู่ใน bound_service_account_names)
- ไม่จำเป็นต้องใช้ ClusterRoleBinding เพราะไม่ได้ใช้ `vault-auth` service account

### UAT Environment Configuration (หลังแก้ไข)

**ไฟล์:** `values-uat.yaml`

```yaml
# ✅ เพิ่ม serviceAccount configuration
serviceAccount:
  create: true
  name: "vault-auth"

vault:
  enabled: true
  address: "https://vault-devops.extosoft.app"
  skipTLSVerify: "true"
  roleName: "k8s-app"
  secrets:
    secretPath: "secret/data/k8s/test-devops-uat"
```

**Service Account ที่ Deployment ใช้:** `vault-auth` ✅

**ClusterRoleBinding:**
- ✅ มี `vault-auth-delegator` สำหรับ `default:vault-auth`
- ✅ มี `vault-auth-delegator-uat` สำหรับ `gke-nonprod-test-devops-uat:vault-auth`

## สรุปความแตกต่าง

| รายการ | Develop | UAT (Before) | UAT (After) |
|--------|---------|--------------|-------------|
| **serviceAccount.name** | ไม่ได้กำหนด | ไม่ได้กำหนด | ✅ `vault-auth` |
| **Service Account ที่ใช้จริง** | `test-devops-develop` | `test-devops-uat` | ✅ `vault-auth` |
| **ClusterRoleBinding** | ไม่จำเป็น | ❌ ไม่มี | ✅ `vault-auth-delegator-uat` |
| **Vault Permission** | ✅ อนุญาต `test-devops-develop` | ✅ อนุญาต `test-devops-uat` & `vault-auth` | ✅ อนุญาต `vault-auth` |
| **Pod Status** | ✅ Running | ❌ ContainerCreating | ✅ Running |

## คำแนะนำสำหรับ Environment อื่นๆ

### ตัวเลือก 1: ใช้ Service Account ที่มีชื่อตาม Environment

**ข้อดี:**
- ไม่ต้องสร้าง ClusterRoleBinding เพิ่ม
- แยก permission ตาม environment ชัดเจน

**ข้อเสีย:**
- ต้องเพิ่ม service account names ทุกตัวใน Vault role

**Configuration:**
```yaml
serviceAccount:
  create: true
  name: "test-devops-<environment>"  # เช่น test-devops-uat, test-devops-staging
```

**Vault role configuration:**
```bash
vault write auth/kubernetes/role/k8s-app \
    bound_service_account_names="test-devops-develop,test-devops-uat,test-devops-staging,test-devops-prod" \
    bound_service_account_namespaces="gke-nonprod-test-devops-develop,gke-nonprod-test-devops-uat,..." \
    policies="k8s-policy" \
    ttl=24h
```

### ตัวเลือก 2: ใช้ Service Account เดียวกัน (vault-auth) ทุก Environment ⭐ แนะนำ

**ข้อดี:**
- Vault role configuration ง่าย (ใช้ service account name เดียว)
- Consistent across environments
- ง่ายต่อการ maintain

**ข้อเสีย:**
- ต้องสร้าง ClusterRoleBinding สำหรับทุก namespace

**Configuration:**
```yaml
# ทุก values-<env>.yaml
serviceAccount:
  create: true
  name: "vault-auth"
```

**ClusterRoleBinding สำหรับแต่ละ namespace:**
```bash
# Develop
kubectl create clusterrolebinding vault-auth-delegator-develop \
  --clusterrole=system:auth-delegator \
  --serviceaccount=gke-nonprod-test-devops-develop:vault-auth

# UAT
kubectl create clusterrolebinding vault-auth-delegator-uat \
  --clusterrole=system:auth-delegator \
  --serviceaccount=gke-nonprod-test-devops-uat:vault-auth

# Staging
kubectl create clusterrolebinding vault-auth-delegator-staging \
  --clusterrole=system:auth-delegator \
  --serviceaccount=gke-nonprod-test-devops-staging:vault-auth
```

**Vault role configuration:**
```bash
vault write auth/kubernetes/role/k8s-app \
    bound_service_account_names="vault-auth" \
    bound_service_account_namespaces="gke-nonprod-test-devops-develop,gke-nonprod-test-devops-uat,gke-nonprod-test-devops-staging" \
    policies="k8s-policy" \
    ttl=24h
```

## Checklist สำหรับ Environment ใหม่

- [ ] สร้าง namespace: `gke-nonprod-test-devops-<env>`
- [ ] สร้าง service account: `vault-auth` ใน namespace
- [ ] สร้าง ClusterRoleBinding: `vault-auth-delegator-<env>`
- [ ] เพิ่ม namespace ใน Vault role: `bound_service_account_namespaces`
- [ ] ตั้งค่า `serviceAccount.name: "vault-auth"` ใน `values-<env>.yaml`
- [ ] ตั้งค่า `vault.secrets.secretPath` ที่ถูกต้อง
- [ ] สร้าง secrets ใน Vault path ที่กำหนด
- [ ] Deploy และทดสอบ

## Files Changed

### Modified
- `/opt/test-devops-gitops/helm/test-devops/values-uat.yaml`
  - เพิ่ม `serviceAccount.create: true`
  - เพิ่ม `serviceAccount.name: "vault-auth"`

### Kubernetes Resources Created
- ClusterRoleBinding: `vault-auth-delegator-uat`

## Git Commits

```bash
commit 1bc98a2
Author: root <root@vault-test-devops>
Date: Sun Nov 24 2025

    Add serviceAccount configuration to values-uat.yaml for Vault authentication
```

## สรุป

ปัญหาเกิดจากการตั้งค่า service account ที่ไม่สอดคล้องกันระหว่าง:
1. ค่าที่ตั้งไว้ใน values file (`vault.serviceAccount`)
2. ค่าที่ deployment ใช้จริง (จาก `serviceAccount.name` หรือ default template)
3. Permission ใน Kubernetes (ClusterRoleBinding)

การแก้ไขที่ถูกต้องคือ:
1. ✅ ตั้งค่า `serviceAccount.name` ให้ชัดเจน
2. ✅ สร้าง ClusterRoleBinding ให้ตรงกับ namespace
3. ✅ ตรวจสอบว่า Vault role อนุญาต service account และ namespace ที่ใช้

---

**หมายเหตุ:** แนะนำให้ใช้วิธีการที่ consistent ทุก environment และสร้าง automation script สำหรับการ setup environment ใหม่เพื่อป้องกันปัญหาแบบนี้ในอนาคต
