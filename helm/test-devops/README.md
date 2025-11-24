# Test-DevOps Helm Chart

Production-ready Helm chart for deploying Node.js applications with HashiCorp Vault integration and external Datadog monitoring.

## Features

- ✅ **Vault-Only Secrets**: All environment variables managed exclusively through HashiCorp Vault
- ✅ **External Datadog**: StatsD metrics to external Datadog agent
- ✅ **Production Ready**: HPA, PDB, Security contexts, Resource limits
- ✅ **Multi-Environment**: Dev, UAT, Production configurations
- ✅ **Ingress Support**: HTTPS ingress with SSL termination and certificates
- ✅ **GitOps Compatible**: ArgoCD/Codefresh deployment ready
- ✅ **No Hardcoded Secrets**: Zero environment variables in values files

## Prerequisites

### Required Kubernetes Components

```bash
# Install Secrets Store CSI Driver
helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm install csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver \
  --namespace kube-system \
  --set syncSecret.enabled=true \
  --set enableSecretRotation=true

# Install Vault CSI Provider
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault-csi-provider hashicorp/vault-csi-provider \
  --namespace kube-system
```

### Vault Configuration

```bash
# Enable Kubernetes auth
vault auth enable kubernetes

# Configure Kubernetes auth
vault write auth/kubernetes/config \
    token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
    kubernetes_host=https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT \
    kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt

# Create policy
vault policy write k8s-app-policy - <<EOF
path "secret/data/k8s/test-devops-*" {
  capabilities = ["read"]
}
EOF

# Create role
vault write auth/kubernetes/role/k8s-app \
    bound_service_account_names=test-app-test-devops \
    bound_service_account_namespaces=default \
    policies=k8s-app-policy \
    ttl=1h
```

## Access URLs

### Environment-Specific URLs

- **Development**: https://test-devops-dev.extosoft.app
- **UAT**: https://test-devops-uat.extosoft.app  
- **Production**: https://test-devops.extosoft.app

### Prerequisites for Ingress

```bash
# Install NGINX Ingress Controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx

# Install cert-manager for SSL certificates
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Create Let's Encrypt ClusterIssuer
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: devops@extosoft.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

## Installation

### Development Environment

```bash
helm install test-app . \
  --values values-dev.yaml \
  --namespace default
```

### UAT Environment

```bash
helm install test-app . \
  --values values-uat.yaml \
  --namespace uat
```

### Production Environment

```bash
helm install test-app . \
  --values values-prod.yaml \
  --namespace production
```

## Configuration

### Values Files

- `values.yaml` - Base configuration
- `values-dev.yaml` - Development overrides
- `values-uat.yaml` - UAT overrides  
- `values-prod.yaml` - Production overrides

### Key Configuration Sections

#### Vault Integration

```yaml
vault:
  enabled: true
  address: "https://vault-devops.extosoft.app"
  skipTLSVerify: true
  role: "k8s-app"
  secretPath: "secret/data/k8s/test-devops-{environment}"
```

#### External Datadog Agent

```yaml
datadog:
  externalAgent:
    enabled: true
    host: "datadog-agent.datadog.svc.cluster.local"
env:
  ddDogstatsdPort: "8125"
```

#### Autoscaling (Production)

```yaml
autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80

podDisruptionBudget:
  enabled: true
  minAvailable: 2
```

#### Ingress Configuration

```yaml
ingress:
  enabled: true
  className: "nginx"
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
  hosts:
    - host: test-devops-dev.extosoft.app  # Development
    - host: test-devops-uat.extosoft.app  # UAT
    - host: test-devops.extosoft.app      # Production
  tls:
    - secretName: test-devops-{env}-tls
      hosts:
        - test-devops-{env}.extosoft.app
```

## Secrets Management

**All environment variables are managed exclusively through Vault secrets:**

- `PORT` - Application port (from Vault)
- `SERVICE_NAME` - Application service name (from Vault)  
- `NODE_ENV` - Node.js environment (from Vault)
- `ENABLE_METRICS` - Datadog metrics flag (from Vault)
- `DD_DOGSTATSD_PORT` - Datadog StatsD port (from Vault)
- `DD_AGENT_HOST` - Datadog agent host (from Vault)
- `STATSD_HOST` - Same as DD_AGENT_HOST (from Vault)

**Vault Secret Paths by Environment:**
- Development: `secret/data/k8s/test-devops-develop`
- UAT: `secret/data/k8s/test-devops-uat`
- Production: `secret/data/k8s/test-devops-production`

**Required Vault Secret Keys:**
```json
{
  "PORT": "3000",
  "NODE_ENV": "develop|uat|production",
  "ENABLE_METRICS": "true",
  "SERVICE_NAME": "test-devops",
  "DD_DOGSTATSD_PORT": "8125",
  "DD_AGENT_HOST": "datadog-agent.datadog.svc.cluster.local"
}
```

## Monitoring

### StatsD Metrics

Application sends metrics via hot-shots client:

```javascript
const StatsD = require('hot-shots');
const dogstatsd = new StatsD({
  host: process.env.STATSD_HOST || process.env.DD_AGENT_HOST,
  port: process.env.DD_DOGSTATSD_PORT || 8125
});
```

### Health Checks

- **Readiness Probe**: `/health/readiness`
- **Liveness Probe**: `/health/liveness`

## Security

### Pod Security Context

```yaml
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1001
  fsGroup: 1001

securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop: ["ALL"]
  readOnlyRootFilesystem: true
```

## Troubleshooting

### Check Vault Secret Injection

```bash
kubectl describe secretproviderclass vault-secrets
kubectl get events --field-selector reason=SecretProviderClassPodStatus
```

### Check External Datadog Connection

```bash
kubectl exec -it deployment/test-app-test-devops -- \
  nc -zv datadog-agent.datadog.svc.cluster.local 8125
```

### View Application Logs

```bash
kubectl logs -f deployment/test-app-test-devops
```

## Development

### Lint Chart

```bash
helm lint
```

### Template Validation

```bash
helm template test-app . --values values-dev.yaml --dry-run
```

### Deploy to Local Cluster

```bash
helm install test-app . \
  --values values-dev.yaml \
  --set vault.enabled=false \
  --dry-run --debug
```

## Chart Structure

```
test-devops/
├── Chart.yaml              # Chart metadata
├── values.yaml             # Default values
├── values-dev.yaml         # Development values
├── values-uat.yaml         # UAT values  
├── values-prod.yaml        # Production values
└── templates/
    ├── _helpers.tpl         # Template helpers
    ├── serviceaccount.yaml  # Service account
    ├── deployment.yaml      # Main deployment
    ├── service.yaml         # Kubernetes service
    ├── hpa.yaml            # Horizontal Pod Autoscaler
    ├── poddisruptionbudget.yaml # Pod Disruption Budget
    └── vault-secretprovider.yaml # Vault CSI integration
```

## Contributing

1. Make changes to templates or values
2. Run `helm lint` to validate
3. Test with `helm template` and `--dry-run`
4. Update this README if needed
5. Commit and push changes

## License

Internal use only - Extosoft DevOps Team