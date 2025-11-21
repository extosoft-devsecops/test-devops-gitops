# 🔧 แก้ปัญหา: "no context exists with the name: docker-desktop"

## สาเหตุ
Kubernetes ใน Docker Desktop ยังไม่ได้เปิดใช้งาน หรือยังไม่ได้ติดตั้ง

---

## วิธีแก้ปัญหา (เลือก 1 วิธี)

### ✅ วิธีที่ 1: เปิดใช้งาน Kubernetes ใน Docker Desktop (แนะนำ)

#### Step 1: เปิด Docker Desktop
- คลิกไอคอน Docker Desktop ที่ menu bar (มุมบนขวา)

#### Step 2: ไปที่ Settings
- คลิก **Preferences** (macOS) หรือ **Settings** (Windows)
- หรือกด `Command + ,` (macOS) / `Ctrl + ,` (Windows)

#### Step 3: เปิด Kubernetes
1. คลิกแท็บ **Kubernetes** ทางด้านซ้าย
2. ✅ เลือก **Enable Kubernetes**
3. (Optional) ✅ เลือก **Show system containers (advanced)**
4. คลิกปุ่ม **Apply & Restart**

#### Step 4: รอให้ Kubernetes เริ่มทำงาน
- Docker Desktop จะ restart
- รอ 2-5 นาที
- เมื่อพร้อมจะเห็น indicator สีเขียว:
  - ✅ "Kubernetes is running"
  - ✅ มี context "docker-desktop" ใน status bar

#### Step 5: ตรวจสอบ
```bash
# ตรวจสอบว่ามี context แล้ว
kubectl config get-contexts

# ควรเห็น docker-desktop
CURRENT   NAME             CLUSTER          AUTHINFO         NAMESPACE
*         docker-desktop   docker-desktop   docker-desktop

# ตรวจสอบ cluster
kubectl cluster-info

# ตรวจสอบ node
kubectl get nodes

# ควรเห็น
NAME             STATUS   ROLES           AGE   VERSION
docker-desktop   Ready    control-plane   1m    v1.28.2
```

---

### 🔄 วิธีที่ 2: ใช้ Minikube แทน

ถ้า Docker Desktop Kubernetes ไม่ทำงาน:

```bash
# 1. Install Minikube
brew install minikube

# 2. Start Minikube
minikube start --driver=docker --cpus=4 --memory=4096

# 3. ตรวจสอบ
kubectl config get-contexts
# ควรเห็น minikube

# 4. ตรวจสอบ node
kubectl get nodes
# ควรเห็น
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   1m    v1.28.2

# 5. Deploy ได้เลย
cd helm/app
make local-start
```

**หยุด Minikube เมื่อเสร็จ:**
```bash
minikube stop
# หรือลบทิ้ง
minikube delete
```

---

### 🐳 วิธีที่ 3: ใช้ Kind (Kubernetes in Docker)

```bash
# 1. Install Kind
brew install kind

# 2. Create cluster
kind create cluster --name test-devops

# 3. ตรวจสอบ
kubectl config get-contexts
# ควรเห็น kind-test-devops

# 4. Deploy
cd helm/app
make local-start
```

**ลบ cluster เมื่อเสร็จ:**
```bash
kind delete cluster --name test-devops
```

---

### 🚫 วิธีที่ 4: ใช้ Docker Compose แทน (ไม่ต้องใช้ Kubernetes)

ถ้าไม่ต้องการใช้ Kubernetes:

```bash
# จาก root ของ project
make run-localhost

# เข้าถึง
open http://localhost:3000
```

**ข้อดี:**
- ไม่ต้อง setup Kubernetes
- เร็วกว่า
- ใช้ resource น้อยกว่า

**ข้อเสีย:**
- ไม่ได้ทดสอบ Helm chart
- ไม่เหมือน production environment

---

## Troubleshooting

### ปัญหา: "no context exists with the name: docker-desktop"

**สาเหตุ:** Kubernetes ยังไม่เคยถูกเปิดใช้งานใน Docker Desktop

**วิธีแก้:**
1. เปิด Docker Desktop
2. Settings → Kubernetes
3. ✅ Enable Kubernetes
4. Apply & Restart
5. รอ 2-5 นาที

### ปัญหา: "cannot delete user docker-desktop, not in config"

**นี่ไม่ใช่ error!** แสดงว่าคุณยังไม่เคยเปิด Kubernetes ใน Docker Desktop

**ไม่ต้องลบอะไร แค่:**
1. เปิด Docker Desktop
2. Settings → Kubernetes  
3. ✅ Enable Kubernetes
4. Apply & Restart

### ปัญหา: Kubernetes ไม่ขึ้นหลัง Enable

**วิธีแก้:**
1. ตรวจสอบ Resources ใน Docker Desktop
   ```
   Settings → Resources
   - CPUs: อย่างน้อย 4
   - Memory: อย่างน้อย 4 GB
   - Swap: อย่างน้อย 2 GB
   ```

2. Reset Kubernetes
   ```
   Settings → Kubernetes → Reset Kubernetes Cluster
   ```

3. Restart Docker Desktop
   ```
   Docker Desktop → Quit Docker Desktop
   จากนั้นเปิดใหม่
   ```

### ปัญหา: "Unable to connect to the server"

**วิธีแก้:**
```bash
# ตรวจสอบว่า Kubernetes running
# ดูที่ Docker Desktop status bar ควรเห็น:
# - Kubernetes: Running (สีเขียว)

# ถ้ายังไม่ running รอสักครู่
# หรือ restart Docker Desktop
```

### ปัญหา: มี context แต่ไม่สามารถใช้งานได้

**วิธีแก้:**
```bash
# Reset Kubernetes ใน Docker Desktop
# Settings → Kubernetes → Reset Kubernetes Cluster
# จากนั้นจะสร้าง context ใหม่ให้อัตโนมัติ
```


---

## ตรวจสอบว่าพร้อมหรือยัง

### Checklist
- [ ] Docker Desktop running
- [ ] Kubernetes enabled (Settings → Kubernetes)
- [ ] Status แสดง "Kubernetes is running" (สีเขียว)
- [ ] `kubectl config get-contexts` แสดง docker-desktop
- [ ] `kubectl get nodes` แสดง docker-desktop Ready

### คำสั่งตรวจสอบ
```bash
# 1. ดู contexts ทั้งหมด
kubectl config get-contexts

# 2. Switch to docker-desktop (ถ้ายังไม่ active)
kubectl config use-context docker-desktop

# 3. ตรวจสอบ cluster
kubectl cluster-info

# 4. ตรวจสอบ nodes
kubectl get nodes

# 5. ทดสอบสร้าง pod
kubectl run test --image=nginx --rm -it --restart=Never -- echo "OK"

# ถ้าเห็น "OK" แสดงว่าพร้อมแล้ว
```

---

## หลังแก้ไขแล้ว

### ทดสอบ deployment
```bash
cd helm/app
make local-start
```

### ถ้ายังมีปัญหา
```bash
# ดู help
./local-test.sh

# หรือ
make help

# หรือใช้ Docker Compose แทน
cd ../..
make run-localhost
```

---

## Resource Requirements

สำหรับ Docker Desktop Kubernetes:

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPUs | 2 | 4 |
| Memory | 2 GB | 4-6 GB |
| Swap | 1 GB | 2 GB |
| Disk | 20 GB | 60 GB |

ตั้งค่าที่: **Docker Desktop → Settings → Resources**

---

## Alternative Solutions Summary

| วิธี | ข้อดี | ข้อเสีย | เวลาติดตั้ง |
|------|-------|---------|-------------|
| Docker Desktop K8s | ใช้งานง่าย, GUI | ใช้ RAM เยอะ | 2-5 นาที |
| Minikube | Lightweight, มี addons | CLI only | 2-3 นาที |
| Kind | เร็ว, multi-cluster | CLI only | 1-2 นาที |
| Docker Compose | เร็วที่สุด | ไม่มี K8s | ทันที |

---

## Quick Commands Reference

```bash
# ตรวจสอบ context
kubectl config get-contexts

# เปลี่ยน context
kubectl config use-context docker-desktop
kubectl config use-context minikube
kubectl config use-context kind-test-devops

# ตรวจสอบ cluster
kubectl cluster-info
kubectl get nodes

# Deploy
cd helm/app
make local-start

# หรือใช้ Docker Compose
cd ../..
make run-localhost
```

---

**🎯 เลือกวิธีที่เหมาะกับคุณ แล้วเริ่มทดสอบได้เลย!**

