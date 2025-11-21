# 🧪 Local Testing Guide - Docker Desktop Kubernetes

## เปิดใช้งาน Kubernetes บน Docker Desktop

### สำหรับ macOS:

1. **เปิด Docker Desktop**
   - คลิกไอคอน Docker Desktop บน menu bar
   
2. **ไปที่ Settings**
   - คลิก Docker Desktop icon → Preferences (หรือ Settings)
   
3. **เปิดใช้งาน Kubernetes**
   - ไปที่แท็บ **Kubernetes**
   - ✅ เลือก **Enable Kubernetes**
   - คลิก **Apply & Restart**
   
4. **รอให้ Kubernetes เริ่มทำงาน**
   - จะเห็น status เป็น "Kubernetes is running" (สีเขียว)
   - อาจใช้เวลา 2-5 นาที

---

## ตรวจสอบ Kubernetes

```bash
# ตรวจสอบ contexts
kubectl config get-contexts

# เปลี่ยนไปใช้ Docker Desktop context
kubectl config use-context docker-desktop

# ตรวจสอบว่า cluster ทำงาน
kubectl cluster-info

# ตรวจสอบ nodes
kubectl get nodes
```

Expected output:
```
NAME             STATUS   ROLES           AGE   VERSION
docker-desktop   Ready    control-plane   1d    v1.28.2
```

---

## วิธีที่ 1: ทดสอบด้วย Docker Compose (ง่ายที่สุด)

ถ้าไม่ต้องการใช้ Kubernetes สามารถทดสอบด้วย Docker Compose:

```bash
# จาก root ของ project
make run-localhost
```

หรือ

```bash
docker compose -f docker-compose-localhost.yaml --env-file .env up --build
```

ตรวจสอบ:
- App: http://localhost:3000
- Graphite: http://localhost:8080

---

## วิธีที่ 2: Deploy Helm Chart บน Docker Desktop Kubernetes

### Prerequisites:
- ✅ Docker Desktop Kubernetes เปิดใช้งานแล้ว
- ✅ Helm 3.x installed
- ⚠️ Datadog API Key (optional สำหรับ local testing)

### Step 1: Switch to Docker Desktop Context

```bash
kubectl config use-context docker-desktop
kubectl get nodes
```

### Step 2: สร้าง Namespace

```bash
kubectl create namespace test-devops-local
```

### Step 3: Deploy แบบไม่มี Datadog (สำหรับ local testing)

สร้างไฟล์ `values-local.yaml`:

```bash
cd helm/app
cat > values-local.yaml << 'EOF'
replicaCount: 1

image:
  repository: asia-southeast1-docker.pkg.dev/test-devops-478606/test-devops-images/test-devops
  tag: "latest"
  pullPolicy: IfNotPresent

service:
  type: NodePort  # เปลี่ยนเป็น NodePort สำหรับ local
  port: 3000
  nodePort: 30080  # เข้าถึงผ่าน localhost:30080

env:
  serviceName: "test-devops"
  enableMetrics: "false"  # ปิด metrics สำหรับ local
  nodeEnv: "local"

resources:
  requests:
    cpu: 50m
    memory: 64Mi
  limits:
    cpu: 200m
    memory: 256Mi

podAnnotations:
  env: "local"

# ปิด Datadog สำหรับ local testing
datadog:
  enabled: false
EOF
```

### Step 4: Build Docker Image Locally (ถ้ายังไม่มี)

```bash
# กลับไป root ของ project
cd ../..

# Build image
docker build -t asia-southeast1-docker.pkg.dev/test-devops-478606/test-devops-images/test-devops:latest .

# ตรวจสอบ
docker images | grep test-devops
```

### Step 5: Deploy Helm Chart

```bash
cd helm/app

helm upgrade --install test-devops-local . \
  -f values-local.yaml \
  --namespace test-devops-local \
  --create-namespace \
  --wait
```

### Step 6: ตรวจสอบ Deployment

```bash
# ดู pods
kubectl get pods -n test-devops-local

# ดู services
kubectl get svc -n test-devops-local

# ดู logs
kubectl logs -n test-devops-local -l app=test-devops-app --tail=50 -f
```

### Step 7: เข้าถึง Application

**Option 1: ผ่าน NodePort**
```bash
# เปิดบราวเซอร์
open http://localhost:30080
```

**Option 2: ผ่าน Port Forward**
```bash
kubectl port-forward -n test-devops-local svc/test-devops-local-test-devops-app 3000:3000
# เปิดบราวเซอร์: http://localhost:3000
```

### Step 8: ทดสอบ API

```bash
# Health check
curl http://localhost:30080/

# ถ้าใช้ port-forward
curl http://localhost:3000/
```

---

## วิธีที่ 3: ใช้ Minikube (ทางเลือก)

ถ้า Docker Desktop Kubernetes ไม่ทำงาน สามารถใช้ Minikube:

```bash
# Install Minikube (ถ้ายังไม่มี)
brew install minikube

# Start Minikube
minikube start --driver=docker

# ตรวจสอบ
kubectl get nodes

# Deploy
cd helm/app
helm upgrade --install test-devops-local . \
  -f values-local.yaml \
  --namespace test-devops-local \
  --create-namespace \
  --wait

# เปิด service
minikube service test-devops-local-test-devops-app -n test-devops-local
```

---

## Debug Commands

### ตรวจสอบ Pod ที่มีปัญหา

```bash
# Describe pod
kubectl describe pod -n test-devops-local <pod-name>

# View logs
kubectl logs -n test-devops-local <pod-name>

# เข้าไปใน pod
kubectl exec -it -n test-devops-local <pod-name> -- sh
```

### ตรวจสอบ Events

```bash
kubectl get events -n test-devops-local --sort-by='.lastTimestamp'
```

### ตรวจสอบ Resources

```bash
kubectl top nodes
kubectl top pods -n test-devops-local
```

---

## Cleanup

### ลบ Helm Release

```bash
helm uninstall test-devops-local -n test-devops-local
```

### ลบ Namespace

```bash
kubectl delete namespace test-devops-local
```

### หยุด Minikube (ถ้าใช้)

```bash
minikube stop
minikube delete
```

---

## Troubleshooting

### ImagePullBackOff Error

ถ้า pod ไม่สามารถ pull image ได้:

```bash
# ใช้ local image โดยตั้งค่า imagePullPolicy
--set image.pullPolicy=Never

# หรือ build image ใน Minikube
eval $(minikube docker-env)
docker build -t test-devops:latest .
```

### Pod ไม่ขึ้น

```bash
# ตรวจสอบ resources
kubectl describe pod -n test-devops-local <pod-name>

# ลด resource requests
--set resources.requests.cpu=10m \
--set resources.requests.memory=32Mi
```

### Service ไม่สามารถเข้าถึงได้

```bash
# ตรวจสอบ endpoints
kubectl get endpoints -n test-devops-local

# ใช้ port-forward แทน
kubectl port-forward -n test-devops-local deployment/test-devops-local-test-devops-app 3000:3000
```

---

## Quick Start Script

สร้างไฟล์ `local-test.sh`:

```bash
#!/bin/bash
set -e

echo "🚀 Starting local Kubernetes test..."

# Check context
CONTEXT=$(kubectl config current-context)
echo "Current context: $CONTEXT"

if [[ "$CONTEXT" != "docker-desktop" && "$CONTEXT" != "minikube" ]]; then
  echo "⚠️  Not using local Kubernetes!"
  echo "Please run: kubectl config use-context docker-desktop"
  exit 1
fi

# Build image
echo "🔨 Building Docker image..."
cd ../..
docker build -t asia-southeast1-docker.pkg.dev/test-devops-478606/test-devops-images/test-devops:latest .

# Deploy
echo "📦 Deploying Helm chart..."
cd helm/app

helm upgrade --install test-devops-local . \
  -f values-local.yaml \
  --namespace test-devops-local \
  --create-namespace \
  --wait

echo "✅ Deployment complete!"
echo ""
echo "Check status:"
echo "  kubectl get pods -n test-devops-local"
echo ""
echo "Access app:"
echo "  http://localhost:30080"
echo "  or"
echo "  kubectl port-forward -n test-devops-local svc/test-devops-local-test-devops-app 3000:3000"
```

ทำให้ executable:

```bash
chmod +x local-test.sh
./local-test.sh
```

---

## สรุป

**แนะนำสำหรับ Local Testing:**

1. **ง่ายที่สุด**: ใช้ `make run-localhost` (Docker Compose)
2. **ทดสอบ Kubernetes**: ใช้ Docker Desktop Kubernetes
3. **ทางเลือก**: ใช้ Minikube

**ข้อดีของแต่ละวิธี:**

| วิธี | ข้อดี | ข้อเสีย |
|------|-------|---------|
| Docker Compose | เร็ว, ง่าย | ไม่เหมือน production |
| Docker Desktop K8s | ใกล้เคียง production | ใช้ resource มาก |
| Minikube | เหมาะกับ testing | ต้อง setup เพิ่ม |

---

**Happy Local Testing! 🎉**

