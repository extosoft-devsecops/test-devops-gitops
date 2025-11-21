# 🚀 Quick Start Guide - Terraform GKE

## ขั้นตอนการใช้งานครั้งแรก (15 นาที)

### 1️⃣ เตรียม Environment

```bash
# Clone repository
cd terraform-gke

# ติดตั้ง Terraform (ถ้ายังไม่มี)
brew install terraform

# ติดตั้ง gcloud CLI (ถ้ายังไม่มี)
brew install --cask google-cloud-sdk

# Login to GCP
gcloud auth application-default login
gcloud config set project test-devops-478606
```

### 2️⃣ เปิดใช้งาน GCP APIs

```bash
make enable-apis

# หรือ
gcloud services enable container.googleapis.com
gcloud services enable compute.googleapis.com
```

### 3️⃣ Setup Backend (GCS)

```bash
# สร้าง GCS bucket สำหรับเก็บ Terraform state
make setup-backend

# คัดลอก backend configuration
cp backend.tf.example backend.tf
```

### 4️⃣ แก้ไข Configuration

**⚠️ สำคัญมาก:** แก้ไข `office_ip` ในไฟล์ tfvars

```bash
# ดู IP ปัจจุบันของคุณ
curl ifconfig.me
# Output: 203.154.1.100 (ตัวอย่าง)

# แก้ไขไฟล์ nonprod.tfvars
vim env/nonprod.tfvars

# เปลี่ยนบรรทัดนี้:
# office_ip = "0.0.0.0/0"
# เป็น:
office_ip = "203.154.1.100/32"  # ใช้ IP ที่ได้จากขั้นตอนก่อนหน้า
```

### 5️⃣ Deploy GKE Cluster

```bash
# Initialize Terraform
make init

# ดูแผนการสร้าง
make plan ENV=nonprod

# สร้าง cluster (ใช้เวลาประมาณ 5-10 นาที)
make apply ENV=nonprod
```

### 6️⃣ Connect to Cluster

```bash
# Connect kubectl
make connect-nonprod

# หรือใช้คำสั่ง gcloud โดยตรง
gcloud container clusters get-credentials gke-nonprod \
  --zone=asia-southeast1-a \
  --project=test-devops-478606

# ทดสอบ
kubectl get nodes
kubectl get pods -A
```

---

## 📋 คำสั่งที่ใช้บ่อย

### Development

```bash
# ดูรายการคำสั่งทั้งหมด
make help

# Format code
make fmt

# Validate configuration
make validate

# Security check
make security-check

# ดู current state
make show

# ดู outputs
make output
```

### Production Deployment

```bash
# แก้ไข prod config
vim env/prod.tfvars

# เปลี่ยน office_ip และ settings ต่างๆ
# แนะนำให้ตั้งค่าเหล่านี้:
# - office_ip = "YOUR_OFFICE_IP/32" (ไม่ใช่ 0.0.0.0/0!)
# - enable_private_endpoint = true
# - regional_cluster = true
# - release_channel = "STABLE"

# Plan สำหรับ production
make prod-plan

# Apply (จะถามยืนยัน)
make prod-apply
```

### Cleanup

```bash
# ลบ nonprod cluster
make destroy ENV=nonprod

# ลบ prod cluster
make destroy ENV=prod
```

---

## 🔍 ตรวจสอบ Cluster

### ดูข้อมูล Cluster

```bash
# ดู cluster info
kubectl cluster-info

# ดู nodes
kubectl get nodes -o wide

# ดู node pools
gcloud container node-pools list --cluster=gke-nonprod --zone=asia-southeast1-a

# ดู resources ทั้งหมด
kubectl get all -A
```

### ดู Logs & Metrics

```bash
# ดู logs ของ pod
kubectl logs -n kube-system <pod-name>

# ดู metrics
kubectl top nodes
kubectl top pods -A

# ดู events
kubectl get events -A --sort-by='.lastTimestamp'
```

---

## 🧪 ทดสอบ Deployment

### Deploy ตัวอย่าง Application

```bash
# สร้าง namespace
kubectl create namespace demo

# Deploy nginx
kubectl create deployment nginx --image=nginx:latest -n demo

# Expose service
kubectl expose deployment nginx --port=80 --type=LoadBalancer -n demo

# ดู service
kubectl get svc -n demo

# ทดสอบ
curl http://<EXTERNAL-IP>
```

### ทดสอบ Autoscaling

```bash
# สร้าง HPA
kubectl autoscale deployment nginx --cpu-percent=50 --min=1 --max=10 -n demo

# ดู HPA
kubectl get hpa -n demo

# สร้าง load test
kubectl run -it load-generator --rm --image=busybox --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://nginx; done"
```

---

## ⚠️ Troubleshooting

### ปัญหา: Cannot create cluster

```bash
# ตรวจสอบ quota
gcloud compute project-info describe --project=test-devops-478606 | grep CPUS

# ตรวจสอบ APIs
gcloud services list --enabled

# ดู error logs
terraform apply -var-file=env/nonprod.tfvars --debug
```

### ปัญหา: Cannot connect to cluster

```bash
# ตรวจสอบ credentials
gcloud container clusters get-credentials gke-nonprod \
  --zone=asia-southeast1-a \
  --project=test-devops-478606

# ตรวจสอบ IP ของคุณ
curl ifconfig.me

# ต้องแน่ใจว่า IP ตรงกับ office_ip ใน tfvars
```

### ปัญหา: Terraform state locked

```bash
# ดู lock
gsutil ls gs://test-devops-terraform-state/terraform/gke/

# Force unlock (ระวัง!)
terraform force-unlock <LOCK_ID>
```

---

## 📊 Cost Estimate

```bash
# ติดตั้ง infracost (optional)
brew install infracost

# ดูค่าใช้จ่ายโดยประมาณ
make cost ENV=nonprod

# ค่าใช้จ่ายโดยประมาณสำหรับ nonprod config:
# - System pool (1 x e2-medium): ~$25/month
# - General pool (1-5 x e2-standard-2): ~$70-350/month
# - Network (VPC, NAT): ~$30/month
# รวม: ~$125-405/month
```

---

## 🔒 Security Checklist

ก่อน Deploy Production:

- [ ] แก้ `office_ip` จาก `0.0.0.0/0` เป็น IP จริง
- [ ] ตั้ง `enable_private_endpoint = true` (ถ้าต้องการ)
- [ ] ตั้ง `regional_cluster = true` (HA)
- [ ] ตั้ง `release_channel = "STABLE"`
- [ ] เปิด `enable_binary_authorization = true` (optional)
- [ ] ตรวจสอบ node pool sizes
- [ ] Setup backup & disaster recovery
- [ ] Configure monitoring alerts
- [ ] Review IAM permissions

---

## 🎯 Next Steps

1. **Deploy Applications**
   - ใช้ Helm charts ใน `helms/test-devops/`
   - Setup ingress controller
   - Configure SSL certificates

2. **Setup CI/CD**
   - GitHub Actions / GitLab CI
   - Automated deployments
   - Testing pipeline

3. **Monitoring & Alerting**
   - Setup Grafana dashboards
   - Configure alerts
   - Log aggregation

4. **Security Hardening**
   - Network policies
   - Pod security standards
   - Image scanning
   - Secrets management (Vault/GCP Secret Manager)

---

## 📚 เอกสารเพิ่มเติม

- [README.md](README.md) - เอกสารฉบับเต็ม
- [REVIEW.md](REVIEW.md) - การวิเคราะห์และข้อเสนอแนะ
- [GKE Best Practices](https://cloud.google.com/kubernetes-engine/docs/best-practices)
- [Terraform GCP Provider Docs](https://registry.terraform.io/providers/hashicorp/google/latest/docs)

---

## 💬 ต้องการความช่วยเหลือ?

```bash
# ดู Terraform outputs
make output

# ดู current configuration
terraform show

# ดู available commands
make help
```

