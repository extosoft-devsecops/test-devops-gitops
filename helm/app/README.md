# Test DevOps Helm Chart

Helm chart สำหรับ deploy Node.js application พร้อม Datadog Agent monitoring

## Services

1. **App Service**: Node.js application with DogStatsD metrics
2. **Datadog Agent**: DaemonSet สำหรับ monitoring และ metrics collection

## Environments

Chart นี้รองรับ 4 environments:

- **develop**: Development environment (GKE)
- **uat**: UAT environment (GKE)
- **prod-gke**: Production environment on Google Kubernetes Engine
- **prod-eks**: Production environment on Amazon EKS

## Image Repository

```
asia-southeast1-docker.pkg.dev/test-devops-478606/test-devops-images/test-devops
```

## Prerequisites

1. Kubernetes cluster (GKE or EKS)
2. Helm 3.x installed
3. Datadog API Key
4. kubectl configured to access your cluster

## Installation

### 1. Create Namespace (if not exists)

```bash
kubectl create namespace test-devops-develop
kubectl create namespace test-devops-uat
kubectl create namespace test-devops-prod
```

### 2. Install for Development Environment

```bash
helm install test-devops ./helm/app \
  -f ./helm/app/values-develop.yaml \
  --set datadog.apiKey=<YOUR_DATADOG_API_KEY> \
  --namespace test-devops-develop
```

### 3. Install for UAT Environment

```bash
helm install test-devops ./helm/app \
  -f ./helm/app/values-uat.yaml \
  --set datadog.apiKey=<YOUR_DATADOG_API_KEY> \
  --namespace test-devops-uat
```

### 4. Install for Production (GKE)

```bash
helm install test-devops ./helm/app \
  -f ./helm/app/values-prod-gke.yaml \
  --set datadog.apiKey=<YOUR_DATADOG_API_KEY> \
  --namespace test-devops-prod
```

### 5. Install for Production (EKS)

```bash
helm install test-devops ./helm/app \
  -f ./helm/app/values-prod-eks.yaml \
  --set datadog.apiKey=<YOUR_DATADOG_API_KEY> \
  --namespace test-devops-prod
```

## Upgrade

```bash
helm upgrade test-devops ./helm/app \
  -f ./helm/app/values-develop.yaml \
  --set datadog.apiKey=<YOUR_DATADOG_API_KEY> \
  --namespace test-devops-develop
```

## Uninstall

```bash
helm uninstall test-devops --namespace test-devops-develop
```

## Configuration

### Key Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of app replicas | `1` |
| `image.repository` | App image repository | `asia-southeast1-docker.pkg.dev/...` |
| `image.tag` | App image tag | `latest` |
| `datadog.enabled` | Enable Datadog Agent | `true` |
| `datadog.apiKey` | Datadog API Key | `""` |
| `datadog.site` | Datadog site | `datadoghq.com` |

### Environment-specific Replicas

- **develop**: 1 replica
- **uat**: 2 replicas
- **prod-gke**: 3 replicas
- **prod-eks**: 3 replicas

### Resource Limits

#### Development
- CPU: 100m - 500m
- Memory: 128Mi - 512Mi

#### UAT
- CPU: 150m - 1000m
- Memory: 192Mi - 1Gi

#### Production
- CPU: 200m - 1500m
- Memory: 256Mi - 2Gi

## Datadog Configuration

### DogStatsD Metrics

Application ส่ง metrics ไปที่ Datadog Agent ผ่าน DogStatsD:

- **Port**: 8125 (UDP)
- **Host**: `DD_AGENT_HOST` (auto-injected via downward API)

### APM (Application Performance Monitoring)

- **Enabled in**: UAT, Production environments
- **Port**: 8126

### Log Collection

- **Enabled**: All environments
- **Auto-discovery**: Collects all container logs

### Process Monitoring

- **Enabled in**: Production environments

### Network Monitoring

- **Enabled in**: Production environments

## Verify Deployment

### Check Pods

```bash
kubectl get pods -n test-devops-develop
```

Expected output:
```
NAME                                 READY   STATUS    RESTARTS   AGE
test-devops-app-xxxxx                1/1     Running   0          1m
test-devops-datadog-agent-xxxxx      1/1     Running   0          1m
```

### Check Services

```bash
kubectl get svc -n test-devops-develop
```

### Check Datadog Agent Logs

```bash
kubectl logs -n test-devops-develop -l app=datadog-agent --tail=50
```

### Test Application

```bash
kubectl port-forward -n test-devops-develop svc/test-devops-app-test-devops-app 3000:3000
```

Then access: http://localhost:3000

## Monitoring

### View Metrics in Datadog

1. Go to https://app.datadoghq.com
2. Navigate to **Metrics** → **Explorer**
3. Search for: `test_devops.request.count`

### View APM Traces

1. Go to **APM** → **Services**
2. Look for `test-devops` service

### View Logs

1. Go to **Logs** → **Live Tail**
2. Filter by: `kube_namespace:test-devops-develop`

## Troubleshooting

### Datadog Agent Not Receiving Metrics

Check if DogStatsD port is accessible:

```bash
kubectl exec -it -n test-devops-develop <app-pod-name> -- nc -zuv $DD_AGENT_HOST 8125
```

### Check Environment Variables

```bash
kubectl exec -it -n test-devops-develop <app-pod-name> -- env | grep DD_
```

### View Datadog Agent Status

```bash
kubectl exec -it -n test-devops-develop <datadog-agent-pod> -- agent status
```

## CI/CD Integration

### GitHub Actions Example

```yaml
- name: Deploy to Develop
  run: |
    helm upgrade --install test-devops ./helm/app \
      -f ./helm/app/values-develop.yaml \
      --set image.tag=${{ github.sha }} \
      --set datadog.apiKey=${{ secrets.DATADOG_API_KEY }} \
      --namespace test-devops-develop \
      --wait
```

## Security Notes

1. **Never commit Datadog API Key** to version control
2. Use `--set` flag or Kubernetes secrets for sensitive data
3. Consider using sealed-secrets or external secret management
4. Review and adjust RBAC permissions as needed

## Support

For issues or questions, contact the DevOps team.

