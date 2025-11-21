# ✅ สรุปการ Config ArgoCD สำหรับ test-devops

## 🎯 สิ่งที่ทำเสร็จแล้ว

### 1. ✅ ปรับปรุง `test-devops-develop.yaml`
- เพิ่ม `namespace: argocd` ใน metadata
- ระบุ `helm.valueFiles` ชี้ไปที่ `values-develop.yaml`
- ตั้งค่า auto sync และ self-heal
- เพิ่ม labels และ finalizers

### 2. ✅ ปรับปรุง `values-develop.yaml`
- เพิ่มค่า configuration ครบถ้วน
- กำหนด image tag สำหรับ Codefresh อัพเดท
- ตั้งค่า resources ให้เหมาะกับ development
- กำหนด health checks และ ingress
- ปิด persistence สำหรับ graphite (ประหยัด cost)

### 3. ✅ สร้างไฟล์สำหรับ Environments อื่นๆ
```
git-sources/codefresh/default/menifest/test-devops/
├── develop/
│   └── test-devops-develop.yaml    ← อัพเดทแล้ว
├── uat/
│   └── test-devops-uat.yaml        ← สร้างใหม่
├── prod/
│   ├── test-devops-prod-gke.yaml   ← สร้างใหม่
│   └── test-devops-prod-eks.yaml   ← สร้างใหม่
├── README.md                        ← สร้างใหม่
└── validate.sh                      ← สร้างใหม่
```

## 📋 ความสัมพันธ์ระหว่างไฟล์

```
ArgoCD Application Manifest
│
├─> test-devops-develop.yaml
│   │
│   ├─> source.path: helms/test-devops
│   ├─> source.helm.valueFiles: [values-develop.yaml]
│   └─> destination.namespace: test-devops-develop
│
└─> Helm Chart (helms/test-devops)
    │
    ├─> values.yaml (default)
    ├─> values-develop.yaml (environment override)
    │   │
    │   ├─> app.image.tag: "develop-latest"  ← Codefresh จะอัพเดท
    │   ├─> app.replicaCount: 1
    │   ├─> app.resources: {...}
    │   └─> graphite.persistence.enabled: false
    │
    └─> templates/
        ├─> app-deployment.yaml
        ├─> app-service.yaml
        ├─> ingress.yaml
        ├─> hpa.yaml
        └─> ...
```

## 🔄 Workflow

### Development Workflow

```
1. Developer Push Code
   ↓
2. Codefresh Pipeline Triggered
   ↓
3. Build Docker Image
   ↓
4. Update values-develop.yaml
   app.image.tag: "develop-abc123"
   ↓
5. Commit & Push to Git
   ↓
6. ArgoCD Detects Change (auto)
   ↓
7. ArgoCD Syncs (auto)
   ↓
8. Deploy to test-devops-develop namespace
```

## 🚀 การใช้งาน

### ตรวจสอบ Configuration

```bash
cd git-sources/codefresh/default/menifest/test-devops

# Validate ทั้งหมด
./validate.sh

# หรือ validate ทีละไฟล์
kubectl apply --dry-run=client -f develop/test-devops-develop.yaml
```

### Apply ไปยัง ArgoCD

```bash
# Development
kubectl apply -f develop/test-devops-develop.yaml

# UAT
kubectl apply -f uat/test-devops-uat.yaml

# Production GKE
kubectl apply -f prod/test-devops-prod-gke.yaml

# ทั้งหมดพร้อมกัน
kubectl apply -f . -R
```

### ตรวจสอบสถานะ

```bash
# List applications
kubectl get applications -n argocd

# Get specific app
argocd app get test-devops-develop

# View manifests
argocd app manifests test-devops-develop

# Watch sync
argocd app sync test-devops-develop --watch
```

## 📊 Environment Comparison

| Feature | Development | UAT | Production |
|---------|------------|-----|------------|
| **Auto Sync** | ✅ Yes | ✅ Yes | ❌ Manual |
| **Self Heal** | ✅ Yes | ✅ Yes | ❌ No |
| **Replicas** | 1 | 2 | 3+ |
| **Resources** | 50m/64Mi | 100m/128Mi | 200m/256Mi |
| **Persistence** | ❌ No | ✅ Yes | ✅ Yes |
| **HPA** | ❌ Disabled | ✅ Enabled | ✅ Enabled |
| **Ingress** | ✅ Yes | ✅ Yes | ✅ Yes (SSL) |
| **Branch** | HEAD/develop | uat | main |

## 🔍 ตรวจสอบว่า ArgoCD อ่าน Helm Values ได้

### วิธีที่ 1: ดูใน ArgoCD UI

1. เปิด ArgoCD UI: http://localhost:8080
2. เลือก Application: `test-devops-develop`
3. ดู **APP DETAILS** → **PARAMETERS**
4. จะเห็น values ที่ merge แล้ว

### วิธีที่ 2: ใช้ CLI

```bash
# ดู application details
argocd app get test-devops-develop

# ดู rendered manifests
argocd app manifests test-devops-develop | less

# ค้นหา image tag
argocd app manifests test-devops-develop | grep "image:"

# ดู values ที่ใช้
argocd app get test-devops-develop -o yaml | grep -A 10 helm
```

### วิธีที่ 3: ทดสอบ Local

```bash
cd helms/test-devops

# Render template
helm template test-devops . -f values-develop.yaml > /tmp/rendered.yaml

# ตรวจสอบ
cat /tmp/rendered.yaml | grep "image:"
cat /tmp/rendered.yaml | grep "replicas:"
```

## 🔧 Codefresh Integration

### Codefresh จะอัพเดท values-develop.yaml

```yaml
# ก่อน Codefresh build
app:
  image:
    tag: "develop-latest"

# หลัง Codefresh build
app:
  image:
    tag: "develop-abc123"  # ← อัพเดทโดย Codefresh
  deployedAt: "2024-01-15T10:30:00Z"
  gitRevision: "abc123def456"
```

### Codefresh Pipeline Step

```yaml
update_helm_values:
  stage: deploy
  image: mikefarah/yq:latest
  commands:
    # อัพเดท image tag
    - yq eval ".app.image.tag = \"$VERSION\"" -i helms/test-devops/values-develop.yaml
    
    # Commit และ push
    - git add helms/test-devops/values-develop.yaml
    - git commit -m "🚀 Update develop image to $VERSION"
    - git push origin develop
```

## ✅ Checklist

### ก่อน Deploy

- [x] ติดตั้ง ArgoCD แล้ว
- [x] เพิ่ม repository ใน ArgoCD
- [x] สร้าง namespace `argocd`
- [x] Validate YAML files
- [x] Test Helm template rendering
- [x] ตรวจสอบ values files อยู่ครบ

### หลัง Deploy

- [ ] Apply ArgoCD Application
- [ ] ตรวจสอบ sync status
- [ ] ตรวจสอบ pods running
- [ ] ทดสอบ ingress/service
- [ ] Setup Codefresh pipeline
- [ ] ทดสอบ end-to-end workflow

## 🚨 Troubleshooting

### ArgoCD ไม่อ่าน values-develop.yaml

```bash
# ตรวจสอบว่าไฟล์มีอยู่จริง
ls -la helms/test-devops/values-develop.yaml

# ตรวจสอบ Application manifest
kubectl get application test-devops-develop -n argocd -o yaml | grep -A 5 helm

# Hard refresh
argocd app get test-devops-develop --hard-refresh
```

### Sync Failed

```bash
# ดู error details
argocd app get test-devops-develop

# ดู logs
kubectl logs -n argocd deployment/argocd-application-controller -f

# Force sync
argocd app sync test-devops-develop --force --prune
```

## 📚 สรุป

**✅ ArgoCD จะอ่าน `helms/test-devops/values-develop.yaml` ได้แล้ว!**

**สิ่งที่ทำ:**
1. ✅ Config `test-devops-develop.yaml` ให้ชี้ไปที่ `values-develop.yaml`
2. ✅ ปรับปรุง `values-develop.yaml` ให้ครบถ้วน
3. ✅ สร้างไฟล์สำหรับ environments อื่นๆ
4. ✅ สร้าง validation script
5. ✅ สร้าง documentation

**วิธีทดสอบ:**
```bash
# 1. Validate
./validate.sh

# 2. Apply
kubectl apply -f develop/test-devops-develop.yaml

# 3. Check
argocd app get test-devops-develop
```

**ผลลัพธ์:**
- ArgoCD จะอ่าน values จาก `values.yaml` + `values-develop.yaml`
- Codefresh จะอัพเดท `values-develop.yaml`
- ArgoCD จะ detect และ sync อัตโนมัติ
- Application จะ deploy ไปยัง `test-devops-develop` namespace

