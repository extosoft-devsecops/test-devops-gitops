# 🚀 Quick Start - Helm Chart Deployment

## Prerequisites
- Kubernetes cluster (GKE or EKS)
- `kubectl` configured
- `helm` 3.x installed
- Datadog API Key

## 5-Minute Deployment

### Step 1: Navigate to Helm Chart
```bash
cd helm/app
```

### Step 2: View Available Commands
```bash
make help
```

### Step 3: Deploy to Development
```bash
make install-develop \
  DATADOG_API_KEY=your-datadog-api-key \
  IMAGE_TAG=latest
```

### Step 4: Check Status
```bash
make status-develop
```

### Step 5: View Logs
```bash
make logs-develop
```

### Step 6: Test Application
```bash
kubectl port-forward -n test-devops-develop svc/test-devops-test-devops-app 3000:3000
```

Open browser: http://localhost:3000

---

## Deploy to Other Environments

### UAT
```bash
make install-uat DATADOG_API_KEY=your-key IMAGE_TAG=uat
```

### Production (GKE)
```bash
make install-prod-gke DATADOG_API_KEY=your-key IMAGE_TAG=v1.0.0
```

### Production (EKS)
```bash
make install-prod-eks DATADOG_API_KEY=your-key IMAGE_TAG=v1.0.0
```

---

## Verify Deployment

### Check All Resources
```bash
kubectl get all -n test-devops-develop
```

Expected output:
```
NAME                                         READY   STATUS    RESTARTS   AGE
pod/test-devops-test-devops-app-xxxxx        1/1     Running   0          1m
pod/test-devops-datadog-agent-xxxxx          1/1     Running   0          1m

NAME                                  TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)    AGE
service/test-devops-test-devops-app   ClusterIP   10.x.x.x      <none>        3000/TCP   1m

NAME                                             DESIRED   CURRENT   READY   AGE
daemonset.apps/test-devops-datadog-agent         1         1         1       1m

NAME                                      READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/test-devops-test-devops-app   1/1     1            1           1m
```

### Test Metrics in Datadog
1. Go to https://app.datadoghq.com
2. Navigate to **Metrics** → **Explorer**
3. Search: `test_devops.request.count`

---

## Cleanup

```bash
make uninstall-develop
```

---

## Need Help?

- Full docs: `helm/app/README.md`
- Summary: `helm/HELM_SUMMARY.md`
- Troubleshooting: See README.md

---

## Common Commands Cheat Sheet

| Action | Command |
|--------|---------|
| Deploy | `make install-develop DATADOG_API_KEY=xxx IMAGE_TAG=v1` |
| Status | `make status-develop` |
| Logs | `make logs-develop` |
| Uninstall | `make uninstall-develop` |
| Test templates | `make test-all` |
| Lint | `make lint` |
| Package | `make package` |

---

**Happy Deploying! 🎉**

