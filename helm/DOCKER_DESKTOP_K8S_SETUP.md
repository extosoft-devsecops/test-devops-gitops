# 🐳 Enable Kubernetes on Docker Desktop (macOS)

## Step-by-Step Guide

### 1. Open Docker Desktop
- คลิกไอคอน Docker Desktop ที่ menu bar (มุมบนขวา)

### 2. Go to Settings
- คลิก Docker Desktop icon → **Preferences** (หรือ **Settings**)
- หรือกด `Command + ,`

### 3. Enable Kubernetes
1. ไปที่แท็บ **Kubernetes** (ด้านซ้าย)
2. ✅ เลือก **Enable Kubernetes**
3. (Optional) ✅ เลือก **Show system containers (advanced)**
4. คลิก **Apply & Restart**

### 4. Wait for Kubernetes to Start
- Docker Desktop จะ restart
- รอให้ Kubernetes เริ่มทำงาน (2-5 นาที)
- เมื่อพร้อมแล้วจะเห็น indicator สีเขียว "Kubernetes is running"

### 5. Verify Installation

```bash
# ตรวจสอบ context
kubectl config get-contexts

# ควรเห็น docker-desktop
CURRENT   NAME             CLUSTER          AUTHINFO         NAMESPACE
*         docker-desktop   docker-desktop   docker-desktop

# Switch to docker-desktop context (ถ้ายังไม่ได้ active)
kubectl config use-context docker-desktop

# ตรวจสอบ cluster
kubectl cluster-info

# ตรวจสอบ node
kubectl get nodes

# ควรเห็น
NAME             STATUS   ROLES           AGE   VERSION
docker-desktop   Ready    control-plane   1d    v1.xx.x
```

---

## Quick Test

```bash
# สร้าง test pod
kubectl run test-nginx --image=nginx --port=80

# ตรวจสอบ
kubectl get pods

# ลบ test pod
kubectl delete pod test-nginx
```

---

## Troubleshooting

### Kubernetes ไม่ขึ้น
1. ตรวจสอบว่า Docker Desktop มี resource เพียงพอ
   - Settings → Resources
   - แนะนำ: CPU ≥ 4, Memory ≥ 4GB
2. Restart Docker Desktop
3. Reset Kubernetes Cluster (Settings → Kubernetes → Reset Kubernetes Cluster)

### Context ไม่เปลี่ยน
```bash
# Force switch
kubectl config use-context docker-desktop

# ตรวจสอบ
kubectl config current-context
```

### Cannot connect to cluster
```bash
# Restart Docker Desktop
# หรือ Reset Kubernetes Cluster
```

---

## Resource Recommendations

สำหรับการรัน Helm chart นี้:
- **CPU**: 4 cores
- **Memory**: 4-6 GB
- **Swap**: 2 GB
- **Disk**: 60 GB

ตั้งค่าใน: **Docker Desktop → Preferences → Resources**

---

## Alternative: Use Minikube

ถ้า Docker Desktop Kubernetes มีปัญหา:

```bash
# Install Minikube
brew install minikube

# Start Minikube
minikube start --driver=docker --cpus=4 --memory=4096

# ตรวจสอบ
kubectl get nodes

# Use Minikube
kubectl config use-context minikube
```

---

## Next Steps

หลังจาก Kubernetes พร้อมแล้ว:

```bash
cd helm/app

# ทดสอบด้วย script
./local-test.sh start

# หรือ deploy ด้วย Helm โดยตรง
helm upgrade --install test-devops-local . \
  -f values-local.yaml \
  --namespace test-devops-local \
  --create-namespace \
  --wait
```

---

## Useful Commands

```bash
# ดู contexts ทั้งหมด
kubectl config get-contexts

# เปลี่ยน context
kubectl config use-context docker-desktop

# ดู current context
kubectl config current-context

# ดู namespaces
kubectl get namespaces

# ดู pods ทั้งหมด
kubectl get pods --all-namespaces
```

---

**Ready to test! 🚀**

