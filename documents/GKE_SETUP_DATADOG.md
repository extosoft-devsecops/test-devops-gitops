# Datadog Setup for GKE Cluster (Non-Prod & Prod)

## 1. Login to Datadog
Login to the Datadog console and generate the required **API Key** and **Application Key**.  
These keys will later be stored inside the Kubernetes cluster as secrets.

## 2. Setup Datadog on GKE Cluster (Non-Prod)

### 2.1 Authenticate with GKE (Cloud Shell)
```bash
gcloud container clusters get-credentials gke-nonprod   --zone <ZONE_NONPROD>   --project <PROJECT_ID>

gcloud config use-context <context-name>
```

### 2.2 Create Datadog Namespace
```bash
kubectl create namespace datadog
```

### 2.3 Create Datadog Values File  
**File: `datadog-values-gke-nonprod.yaml`**
```yaml
datadog:
  site: datadoghq.com
  apiKeyExistingSecret: datadog-secret
  appKeyExistingSecret: datadog-secret

  tags:
    - "cluster:gke-nonprod"
    - "env:nonprod"

  logs:
    enabled: true
    containerCollectAll: true

  apm:
    enabled: true

  processAgent:
    enabled: true

  kubeStateMetricsEnabled: false
  kubeStateMetricsCore:
    enabled: true

clusterAgent:
  enabled: true
  metricsProvider:
    enabled: true
    useDatadogMetrics: true

confd:
  kubernetes_state_core.yaml: |
    init_config: {}
    instances:
      - collectors:
          - nodes
          - nodes_status
          - nodes_conditions
          - pods
          - deployments
          - replicasets
          - statefulsets
          - daemonsets

rbac:
  create: true
```

### 2.4 Create Datadog API Key Secret
```bash
kubectl create secret generic datadog-secret   -n datadog   --from-literal api-key='<YOUR_API_KEY>'   --from-literal app-key='<YOUR_APP_KEY>'
```

### 2.5 Install Datadog Using Helm
```bash
helm repo add datadog https://helm.datadoghq.com
helm repo update

helm install datadog-agent datadog/datadog   -n datadog   -f datadog-values-gke-nonprod.yaml
```

### 2.6 Verify Datadog Pods
```bash
kubectl get pods -n datadog
```

## 3. Setup Datadog for GKE Cluster (Production)
Follow the same steps as non-prod with production values.

## 4. Validation Checklist
- Datadog Agent running on all nodes  
- Cluster Agent healthy  
- Logs visible  
- APM visible  
- Node metrics available  

**อัปเดตล่าสุด**: วันที่ 24 พฤศจิกายน 2025