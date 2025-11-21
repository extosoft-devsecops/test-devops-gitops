# Terraform-GKE
Internal use only - Extosoft

## 📄 License

4. Submit PR
3. Test thoroughly
2. Make changes
1. Create feature branch

## 🤝 Contributing

- [GKE Best Practices](https://cloud.google.com/kubernetes-engine/docs/best-practices)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)

## 📚 Additional Resources

3. VPN/Proxy configuration
2. Private endpoint setting
1. IP ของคุณอยู่ใน master_authorized_networks
ตรวจสอบ:

### Error: Can't connect to cluster

   ```
   gcloud compute project-info describe --project=test-devops-478606
   ```bash
2. มี quota เพียงพอ

   ```
   gcloud services enable compute.googleapis.com
   gcloud services enable container.googleapis.com
   ```bash
1. GCP API ถูกเปิดใช้งานแล้ว
ตรวจสอบ:

### Error: Cluster creation failed

## 🐛 Troubleshooting

```
terraform plan -var-file=env/nonprod.tfvars

export TF_VAR_office_ip="$(curl -s ifconfig.me)/32"
export TF_VAR_project_id="test-devops-478606"
```bash

สำหรับ variables ที่เป็นความลับ สามารถใช้ environment variables:

## 📝 Environment Variables

```
  --quiet
  --zone=asia-southeast1-a \
gcloud container clusters delete gke-nonprod \
# หรือใช้ gcloud

terraform destroy -var-file=env/nonprod.tfvars
# ลบ cluster
```bash

## 🗑️ Cleanup

```
terraform show tfplan
terraform plan -var-file=env/nonprod.tfvars -out=tfplan
# See what will be created
```bash
### Dry Run

```
terraform plan -var-file=env/nonprod.tfvars
# Plan without apply

terraform validate
# Validate

terraform fmt -recursive
# Format code
```bash
### Validate Configuration

## 🧪 Testing

```
  --master
  --zone=asia-southeast1-a \
gcloud container clusters upgrade gke-nonprod \
# Upgrade cluster

gcloud container get-server-config --region=asia-southeast1
# List available versions
```bash
### Manual Upgrade

- Production: 02:00 UTC
- Non-prod: 03:00 UTC
Nodes จะ auto-upgrade ตาม maintenance window ที่กำหนด:
### Auto-upgrade

## 🔄 Maintenance

```
gcloud logging read "resource.type=k8s_cluster" --limit 50
# ดู logs

https://console.cloud.google.com/kubernetes/clusters
# ดู cluster ใน GCP Console
```bash
ดู metrics ได้ที่:

- **Managed Prometheus** - สำหรับ advanced monitoring
- **Cloud Monitoring** - metrics และ dashboard
- **Cloud Logging** - ทุก logs จาก system และ workloads
GKE เปิดใช้งาน:

## 📊 Monitoring & Logging

- General pool: 1-10 nodes (nonprod), 2-20 nodes (prod)
- System pool: 1-3 nodes
GKE จะ autoscale nodes ตาม workload อัตโนมัติ:
### Cluster Autoscaler

```
    pool: spot
  nodeSelector:
    effect: "NoSchedule"
    value: "true"
    operator: "Equal"
  - key: "cloud.google.com/gke-spot"
  tolerations:
spec:
  name: batch-job
metadata:
kind: Pod
apiVersion: v1
```yaml
ตัวอย่างการใช้งานใน Kubernetes:

```
spot_max_nodes   = 10
enable_spot_pool = true
```terraform

เปิดใช้งาน Spot VM node pool สำหรับ workloads ที่ไม่ critical:
### Spot VMs

## 💰 Cost Optimization

```
enable_binary_authorization = true
release_channel          = "STABLE"
regional_cluster         = true
enable_private_endpoint  = true
# ใน prod.tfvars
```terraform

### 🔒 Production Recommendations:

5. **Binary Authorization** - ตรวจสอบ container images
4. **Regional Cluster** (Production) - สำหรับ High Availability
3. **Enable Private Endpoint** (Production) - ปิด public access ไปยัง control plane
2. **ใช้ GCS Backend** - สำหรับ state locking และ backup

   ```
   office_ip = "203.154.1.1/32"  # IP ของ office
   ```terraform
1. **แก้ไข office_ip** - ระบุ IP ที่เฉพาะเจาะจง ไม่ใช่ `0.0.0.0/0`

### ⚠️ สิ่งที่ควรทำ:

## 🔐 Security Best Practices

3. **Spot Pool** (Optional) - Spot VMs สำหรับประหยัดค่าใช้จ่าย
2. **General Pool** - สำหรับ application workloads ทั่วไป
1. **System Pool** - สำหรับ system workloads (kube-system, logging, monitoring)
#### Node Pools:

- ✅ Shielded GKE Nodes
- ✅ Auto-upgrade & Auto-repair
- ✅ Managed Prometheus
- ✅ Dataplane V2 (eBPF)
- ✅ Network Policy
- ✅ Release Channel (REGULAR/STABLE)
- ✅ Master Authorized Networks
- ✅ Workload Identity
- ✅ Private Cluster (private nodes)
#### Cluster Features:

### GKE Module

- Private Google Access
- Cloud Router และ Cloud NAT สำหรับ private nodes
- Subnet พร้อม secondary IP ranges สำหรับ Pods และ Services
- Custom VPC network

สร้าง VPC, Subnet, Cloud NAT สำหรับ GKE:

### Network Module

## 🔧 Configuration

```
        └── outputs.tf
        ├── variables.tf
        ├── iam.tf
        ├── nodepools.tf
        ├── cluster.tf
    └── gke/              # GKE Cluster module
    │   └── outputs.tf
    │   ├── variables.tf
    │   ├── main.tf
    ├── network/           # VPC & Networking module
└── modules/
│   └── prod.tfvars        # Production settings
│   ├── nonprod.tfvars     # Non-production settings
├── env/                    # Environment-specific configs
├── versions.tf             # Provider versions
├── outputs.tf              # Output values
├── variables.tf            # Input variables
├── main.tf                 # Main configuration
├── backend.tf              # Remote state configuration
terraform-gke/
```

## 📁 โครงสร้างโปรเจค

```
kubectl get nodes
# ทดสอบ connection

  --project=test-devops-478606
  --zone=asia-southeast1-a \
gcloud container clusters get-credentials gke-nonprod \
# Get credentials
```bash

### 5. Connect to Cluster

```
terraform apply -var-file=env/nonprod.tfvars
# สร้าง GKE Cluster

terraform plan -var-file=env/nonprod.tfvars
# ดูแผนการสร้าง resources

terraform init
# Initialize Terraform
```bash

### 4. Deploy

```
# เปลี่ยน office_ip = "0.0.0.0/0" เป็น office_ip = "YOUR_IP/32"
vim env/nonprod.tfvars
# แก้ไขไฟล์

curl ifconfig.me
# ดู IP ปัจจุบันของคุณ
```bash

**⚠️ สำคัญ:** แก้ไข `office_ip` ในไฟล์ tfvars ให้เป็น IP จริงของคุณ

### 3. ตั้งค่า Variables

```
# แก้ไข bucket name ใน backend.tf ถ้าต้องการ
cp backend.tf.example backend.tf
```bash
คัดลอก backend configuration:

```
gsutil versioning set on gs://test-devops-terraform-state
# เปิด versioning

gsutil mb -p test-devops-478606 -l asia-southeast1 gs://test-devops-terraform-state
# สร้าง bucket
```bash

สร้าง GCS bucket สำหรับเก็บ Terraform state:

### 2. ตั้งค่า Backend (GCS)

```
gcloud auth application-default login
# Login to GCP

brew install --cask google-cloud-sdk
# ติดตั้ง Google Cloud SDK

brew install terraform
# ติดตั้ง Terraform
```bash

### 1. ติดตั้ง Dependencies

## 🚀 Quick Start

- สิทธิ์ในการสร้าง GKE Cluster บน GCP Project
- Google Cloud SDK (gcloud CLI)
- Terraform >= 1.6.0

## 📋 ข้อกำหนดเบื้องต้น

Terraform modules สำหรับสร้างและจัดการ Google Kubernetes Engine (GKE) บน Google Cloud Platform


