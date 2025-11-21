# Test DevOps Helm Chart - Quick Reference

## 🚀 Quick Commands

### Installation
```bash
# Development
helm install test-devops-dev . -f values-develop.yaml

# UAT  
helm install test-devops-uat . -f values-uat.yaml

# Production GKE
helm install test-devops-prod . -f values-prod-gke.yaml

# Production EKS
helm install test-devops-prod . -f values-prod-eks.yaml
```

### Upgrade
```bash
helm upgrade test-devops-prod . -f values-prod-gke.yaml
```

### Uninstall
```bash
helm uninstall test-devops-prod
```

## 📊 Environment Comparison

| Environment  | Replicas | CPU    | Memory  | Storage   | Ingress | Purpose                     |
|--------------|----------|--------|---------|-----------|---------|-----------------------------|
| **Develop**  | 1        | 100m   | 128Mi   | EmptyDir  | ❌       | Local dev/testing           |
| **UAT**      | 2        | 200m   | 256Mi   | 1Gi       | ❌       | User acceptance testing     |
| **Prod-GKE** | 3        | 500m   | 512Mi   | 10Gi      | ✅ GCE   | Google Cloud production     |
| **Prod-EKS** | 3        | 500m   | 512Mi   | 10Gi      | ✅ ALB   | AWS production              |

## 🔍 Useful Commands

### Health Checks
```bash
# Check all pods
kubectl get pods -l app.kubernetes.io/instance=test-devops-prod

# Check application logs
kubectl logs -f deployment/test-devops-prod-app

# Check Graphite logs  
kubectl logs -f deployment/test-devops-prod-graphite
```

### Access Services
```bash
# Application port-forward
kubectl port-forward svc/test-devops-prod-app 8080:3000

# Graphite dashboard port-forward
kubectl port-forward svc/test-devops-prod-graphite 8080:80
```

### Troubleshooting
```bash
# Describe pod issues
kubectl describe pod <pod-name>

# Check persistent volume
kubectl get pvc test-devops-prod-graphite-data

# View chart values
helm get values test-devops-prod
```

## 📈 Monitoring Access

1. **Graphite Dashboard**: `http://localhost:8080` (after port-forward)
2. **Application Health**: `http://localhost:8080/healthz` 
3. **Application Ready**: `http://localhost:8080/ready`

## ⚙️ Common Customizations

### Scale Application
```yaml
app:
  replicaCount: 5
```

### Enable Ingress
```yaml
ingress:
  enabled: true
  className: "nginx"
  hosts:
    - host: api.example.com
      paths:
        - path: /
          pathType: Prefix
```

### Increase Resources
```yaml
app:
  resources:
    limits:
      cpu: 1000m
      memory: 1Gi
    requests:
      cpu: 500m
      memory: 512Mi
```

---
🎯 **Ready to deploy!** Choose your environment and run the installation command.