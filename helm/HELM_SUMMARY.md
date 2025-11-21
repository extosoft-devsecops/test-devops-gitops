# Helm Chart Summary - Test DevOps

## ✅ สรุปสิ่งที่สร้างเสร็จแล้ว

### 🎯 Services (2 รายการ)
1. **App Service** - Node.js Application
2. **Datadog Agent** - Monitoring & Metrics Collection (DaemonSet)

### 🌍 Environments (4 รายการ)
1. **develop** - Development environment (1 replica)
2. **uat** - UAT environment (2 replicas)
3. **prod-gke** - Production on GKE (3 replicas)
4. **prod-eks** - Production on EKS (3 replicas)

### 📦 Image Repository
```
asia-southeast1-docker.pkg.dev/test-devops-478606/test-devops-images/test-devops
```

---

## 📁 โครงสร้างไฟล์

```
helm/app/
├── Chart.yaml                      # Helm chart metadata
├── values.yaml                     # Default values
├── values-develop.yaml             # Develop environment config
├── values-uat.yaml                 # UAT environment config
├── values-prod-gke.yaml            # Production GKE config
├── values-prod-eks.yaml            # Production EKS config
├── Makefile                        # Make commands for deployment
├── deploy.sh                       # Deploy script (executable)
├── create-datadog-secrets.sh       # Secret creation script (executable)
├── README.md                       # Full documentation
└── templates/
    ├── NOTES.txt                   # Post-install notes
    ├── _helpers.tpl                # Template helpers
    ├── deployment.yaml             # App deployment
    ├── service.yaml                # App service
    ├── datadog-daemonset.yaml      # Datadog agent DaemonSet
    ├── datadog-serviceaccount.yaml # Datadog service account
    ├── datadog-rbac.yaml           # Datadog RBAC
    └── datadog-secret.yaml         # Datadog API key secret
```

---

## 🚀 การใช้งาน

### วิธีที่ 1: ใช้ Makefile (แนะนำ)

```bash
# View available commands
cd helm/app
make help

# Lint chart
make lint

# Test templates
make test-all

# Deploy to develop
make install-develop DATADOG_API_KEY=your-key IMAGE_TAG=v1.0.0

# Deploy to UAT
make install-uat DATADOG_API_KEY=your-key IMAGE_TAG=v1.0.0

# Deploy to Production (GKE)
make install-prod-gke DATADOG_API_KEY=your-key IMAGE_TAG=v1.0.0

# Deploy to Production (EKS)
make install-prod-eks DATADOG_API_KEY=your-key IMAGE_TAG=v1.0.0

# Check status
make status-develop
make status-uat
make status-prod

# View logs
make logs-develop
make logs-uat
make logs-prod

# Uninstall
make uninstall-develop
```

### วิธีที่ 2: ใช้ deploy.sh script

```bash
cd helm/app

# Deploy to develop
./deploy.sh develop v1.0.0 your-datadog-api-key

# Deploy to UAT
./deploy.sh uat v1.0.0 your-datadog-api-key

# Deploy to production GKE
./deploy.sh prod-gke v1.0.0 your-datadog-api-key

# Deploy to production EKS
./deploy.sh prod-eks v1.0.0 your-datadog-api-key
```

### วิธีที่ 3: ใช้ Helm command โดยตรง

```bash
# Install to develop
helm upgrade --install test-devops ./helm/app \
  -f ./helm/app/values-develop.yaml \
  --set image.tag=v1.0.0 \
  --set datadog.apiKey=your-key \
  --namespace test-devops-develop \
  --create-namespace \
  --wait

# Install to UAT
helm upgrade --install test-devops ./helm/app \
  -f ./helm/app/values-uat.yaml \
  --set image.tag=v1.0.0 \
  --set datadog.apiKey=your-key \
  --namespace test-devops-uat \
  --create-namespace \
  --wait

# Install to Production (GKE)
helm upgrade --install test-devops ./helm/app \
  -f ./helm/app/values-prod-gke.yaml \
  --set image.tag=v1.0.0 \
  --set datadog.apiKey=your-key \
  --namespace test-devops-prod \
  --create-namespace \
  --wait

# Install to Production (EKS)
helm upgrade --install test-devops ./helm/app \
  -f ./helm/app/values-prod-eks.yaml \
  --set image.tag=v1.0.0 \
  --set datadog.apiKey=your-key \
  --namespace test-devops-prod \
  --create-namespace \
  --wait
```

---

## ⚙️ Configuration ตาม Environment

### Development
- **Replicas**: 1
- **Resources**: 100m-500m CPU, 128Mi-512Mi Memory
- **Datadog Features**: Basic monitoring, DogStatsD, Logs, Process Agent

### UAT
- **Replicas**: 2
- **Resources**: 150m-1000m CPU, 192Mi-1Gi Memory
- **Datadog Features**: + APM enabled

### Production (GKE & EKS)
- **Replicas**: 3
- **Resources**: 200m-1500m CPU, 256Mi-2Gi Memory
- **Datadog Features**: + APM, Process Agent, Network Monitoring
- **Image Pull Policy**: Always

---

## 📊 Datadog Features

### ทุก Environment
- ✅ DogStatsD Metrics (Port 8125)
- ✅ Log Collection (All containers)
- ✅ Process Agent
- ✅ Auto-discovery

### UAT และ Production เท่านั้น
- ✅ APM (Application Performance Monitoring)
- ✅ Network Monitoring (Production only)

### Environment Variables (Auto-injected)
```yaml
DD_AGENT_HOST: <node-ip>        # Auto from downward API
DD_DOGSTATSD_PORT: 8125
SERVICE_NAME: test-devops
NODE_ENV: develop/uat/prod-gke/prod-eks
```

---

## 🔐 Secret Management

### วิธีที่ 1: ใช้ --set flag (สำหรับ testing)
```bash
helm install ... --set datadog.apiKey=your-key
```

### วิธีที่ 2: ใช้ script สร้าง Kubernetes Secret
```bash
./create-datadog-secrets.sh your-datadog-api-key
```

### วิธีที่ 3: ใช้ CI/CD secrets
```yaml
# GitHub Actions example
--set datadog.apiKey=${{ secrets.DATADOG_API_KEY }}
```

---

## ✅ การทดสอบ

```bash
# Lint chart
helm lint ./helm/app

# Dry run
helm install test-devops ./helm/app \
  -f ./helm/app/values-develop.yaml \
  --dry-run --debug

# Template validation
helm template test-devops ./helm/app \
  -f ./helm/app/values-develop.yaml

# Run all tests
cd helm/app && make test-all
```

---

## 📝 ตรวจสอบการ Deploy

### Check Pods
```bash
kubectl get pods -n test-devops-develop
kubectl get pods -n test-devops-uat
kubectl get pods -n test-devops-prod
```

### Check Services
```bash
kubectl get svc -n test-devops-develop
```

### View Logs
```bash
# App logs
kubectl logs -n test-devops-develop -l app=test-devops-app --tail=50 -f

# Datadog Agent logs
kubectl logs -n test-devops-develop -l app=datadog-agent --tail=50
```

### Port Forward
```bash
kubectl port-forward -n test-devops-develop svc/test-devops-test-devops-app 3000:3000
# Then open: http://localhost:3000
```

### Check Datadog Agent Status
```bash
kubectl exec -n test-devops-develop <datadog-pod> -- agent status
```

---

## 🎯 Kubernetes Resources ที่ถูกสร้าง

### Application
- ✅ Deployment (app pods)
- ✅ Service (ClusterIP)

### Datadog
- ✅ DaemonSet (runs on all nodes)
- ✅ ServiceAccount
- ✅ ClusterRole
- ✅ ClusterRoleBinding
- ✅ Secret (API key)

---

## 📚 เอกสารเพิ่มเติม

- **Full README**: `helm/app/README.md`
- **Datadog Docs**: https://docs.datadoghq.com/
- **Helm Docs**: https://helm.sh/docs/

---

## 🛠️ Troubleshooting

### ถ้า Pods ไม่ทำงาน
```bash
kubectl describe pod -n test-devops-develop <pod-name>
kubectl logs -n test-devops-develop <pod-name>
```

### ถ้า Metrics ไม่ขึ้น Datadog
```bash
# Check DD_AGENT_HOST
kubectl exec -n test-devops-develop <app-pod> -- env | grep DD_

# Check Datadog Agent
kubectl get pods -n test-devops-develop -l app=datadog-agent
kubectl logs -n test-devops-develop <datadog-pod>

# Test connection
kubectl exec -n test-devops-develop <app-pod> -- nc -zuv $DD_AGENT_HOST 8125
```

---

## 🎉 สรุป

Helm chart พร้อมใช้งานแล้ว! มี:
- ✅ 2 Services (App + Datadog Agent)
- ✅ 4 Environments (develop, uat, prod-gke, prod-eks)
- ✅ Image จาก GCP Artifact Registry
- ✅ Complete Datadog monitoring
- ✅ Scripts สำหรับ deployment
- ✅ Makefile สำหรับจัดการง่าย
- ✅ Documentation ครบถ้วน

**ทดสอบแล้วด้วย `helm lint` และ `helm template` ผ่านทั้งหมด! 🎊**

