# Codefresh Direct Deploy (ไม่ใช้ GitOps/ArgoCD)

Pipeline นี้จะ deploy Helm chart ไปยัง Kubernetes โดยตรงผ่าน Codefresh

## 🎯 Workflow

```
1. Push Code to Branch
   ↓
2. Codefresh Triggered
   ↓
3. Clone Repository
   ↓
4. Build Docker Image
   ↓
5. Run Helm Tests (lint, template)
   ↓
6. Push Image to GCR
   ↓
7. Deploy to Kubernetes ด้วย helm upgrade --install
   ↓
8. Verify Deployment
   ↓
9. Slack Notification
```

## 📋 Environment Mapping

| Branch | Environment | Namespace | Cluster |
|--------|-------------|-----------|---------|
| `develop` | develop | test-devops-develop | gke-nonprod |
| `uat` | uat | test-devops-uat | gke-nonprod |
| `main` | prod-gke | test-devops-prod | gke-prod |

## 🚀 Setup

### 1. Add Kubernetes Cluster to Codefresh

```bash
# ใน Codefresh UI → Account Settings → Integrations → Kubernetes

# หรือใช้ CLI
codefresh create context kubernetes \
  --name gke-nonprod \
  --cluster-name gke_test-devops-478606_asia-southeast1-a_gke-nonprod
```

### 2. Configure Variables

ใน Codefresh UI → Pipeline Settings → Variables:

```bash
# GCP Service Account (สำหรับ GCR)
GCP_SA_KEY=<base64-encoded-service-account-key>

# Slack Notification (optional)
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL

# Kubernetes Contexts (auto-configured)
KUBE_CONTEXT=<cluster-context-name>
```

### 3. Create Pipeline

```bash
# ใน Codefresh UI → Projects → Pipelines → New Pipeline
# Inline YAML: ใช้ codefresh.yaml

# หรือใช้ CLI
codefresh create pipeline \
  --name test-devops \
  --project test-devops \
  --spec-yaml codefresh.yaml
```

### 4. Setup Triggers

```yaml
triggers:
  - name: develop-trigger
    type: git
    repo: extosoft-devsecops/test-devops-gitops
    events:
      - push.heads
    branchRegex: /^develop$/
    
  - name: uat-trigger
    type: git
    repo: extosoft-devsecops/test-devops-gitops
    events:
      - push.heads
    branchRegex: /^uat$/
    
  - name: main-trigger
    type: git
    repo: extosoft-devsecops/test-devops-gitops
    events:
      - push.heads
    branchRegex: /^main$/
    pullRequestTargetBranchRegex: /^main$/
```

## 🔧 การใช้งาน

### Deploy Development

```bash
# Push to develop branch
git checkout develop
git add .
git commit -m "Update feature"
git push origin develop

# Codefresh จะ auto trigger และ:
# 1. Build image: gcr.io/.../test-devops:develop-abc123
# 2. Deploy to: test-devops-develop namespace
# 3. Using values: values-develop.yaml
```

### Deploy UAT

```bash
# Push to uat branch
git checkout uat
git merge develop
git push origin uat

# Deploy to: test-devops-uat namespace
# Using values: values-uat.yaml
```

### Deploy Production

```bash
# Merge PR to main
git checkout main
git merge uat
git push origin main

# Deploy to: test-devops-prod namespace
# Using values: values-prod-gke.yaml
```

## 📊 Pipeline Steps Detail

### 1. Prepare Stage
- Clone repository
- Export version variables
- Set environment variables

### 2. Build Stage
- Build Docker image
- Tag with version and branch

### 3. Test Stage
- Helm lint
- Helm template dry-run
- Validate manifests

### 4. Deploy Stage
- Push image to GCR
- Deploy to Kubernetes with `helm upgrade --install`
- Override values:
  ```yaml
  app.image.tag: develop-abc123
  app.deployedAt: 20240115-103000
  app.gitRevision: abc123def456
  app.deployedBy: codefresh
  ```

### 5. Verify Stage
- Check deployment status
- Wait for pods ready
- Get service/ingress info
- Show helm status

### 6. Notify Stage
- Send Slack notification (success/failure)

## 🔍 Monitoring

### View Deployment Status

```bash
# ใน Codefresh UI
https://g.codefresh.io/pipelines/test-devops

# หรือใช้ CLI
codefresh get builds --pipeline test-devops --limit 10
```

### View Logs

```bash
# Real-time logs
codefresh logs <build-id> --follow

# Specific step
codefresh logs <build-id> --step deploy_to_kubernetes
```

### Kubernetes Resources

```bash
# Development
kubectl get all -n test-devops-develop

# UAT
kubectl get all -n test-devops-uat

# Production
kubectl get all -n test-devops-prod
```

## 🔄 Rollback

### วิธีที่ 1: Helm Rollback

```bash
# List releases
helm list -n test-devops-develop

# Rollback to previous version
helm rollback test-devops -n test-devops-develop

# Rollback to specific revision
helm rollback test-devops 5 -n test-devops-develop
```

### วิธีที่ 2: Rebuild Previous Commit

```bash
# ใน Codefresh UI
1. ไปที่ Pipeline → Builds
2. เลือก build ที่ต้องการ
3. คลิก "Rebuild"
```

### วิธีที่ 3: Revert Git Commit

```bash
git revert <commit-hash>
git push origin develop
# Codefresh จะ trigger อัตโนมัติ
```

## ⚙️ Advanced Configuration

### Custom Values Override

แก้ไข `codefresh.yaml`:

```yaml
deploy_to_kubernetes:
  commands:
    - |
      helm upgrade --install test-devops helms/test-devops \
        --set app.replicaCount=3 \
        --set app.resources.limits.cpu=500m \
        --set app.resources.limits.memory=512Mi
```

### Multi-Cluster Deploy

```yaml
variables:
  - key: KUBE_CONTEXT_GKE
    value: gke-prod
  - key: KUBE_CONTEXT_EKS
    value: eks-prod

steps:
  deploy_to_gke:
    commands:
      - kubectl config use-context ${{KUBE_CONTEXT_GKE}}
      - helm upgrade --install ...
  
  deploy_to_eks:
    commands:
      - kubectl config use-context ${{KUBE_CONTEXT_EKS}}
      - helm upgrade --install ...
```

### Approval Step (Manual Gate)

```yaml
steps:
  approval:
    stage: deploy
    type: pending-approval
    title: Approve Production Deployment
    when:
      branch:
        only: [main]
  
  deploy_to_kubernetes:
    stage: deploy
    depends_on:
      - approval
```

## 🚨 Troubleshooting

### Build Failed

```bash
# ดู logs
codefresh logs <build-id>

# Rebuild with debug
codefresh run test-devops --branch develop --debug
```

### Deploy Failed

```bash
# ตรวจสอบ cluster connection
kubectl cluster-info

# ตรวจสอบ context
kubectl config get-contexts

# ทดสอบ helm locally
helm upgrade --install test-devops helms/test-devops \
  -f helms/test-devops/values-develop.yaml \
  --dry-run --debug
```

### Image Pull Failed

```bash
# ตรวจสอบ image
gcloud container images list --repository=gcr.io/test-devops-478606/test-devops-images

# ตรวจสอบ credentials
kubectl get secret -n test-devops-develop
```

## 📚 Resources

- [Codefresh Helm Documentation](https://codefresh.io/docs/docs/deployments/helm/using-helm-in-codefresh-pipeline/)
- [Codefresh Kubernetes Integration](https://codefresh.io/docs/docs/deployments/kubernetes/)
- [Helm Chart](../helms/test-devops/README.md)

## ✅ Checklist

### Setup
- [ ] Add Kubernetes cluster to Codefresh
- [ ] Configure GCP credentials
- [ ] Create pipeline
- [ ] Setup triggers
- [ ] Configure Slack webhook (optional)

### Testing
- [ ] Test build locally
- [ ] Test helm template
- [ ] Test deploy to develop
- [ ] Verify pods running
- [ ] Test rollback

### Production
- [ ] Review production values
- [ ] Setup approval gate
- [ ] Configure monitoring
- [ ] Document deployment process
- [ ] Test disaster recovery

