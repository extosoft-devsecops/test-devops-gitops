# Test DevOps Helm Chart

A comprehensive Helm chart for deploying the Test DevOps application with integrated Graphite/StatsD monitoring on Kubernetes.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Environment-Specific Deployments](#environment-specific-deployments)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)
- [Development](#development)

## 🎯 Overview

This Helm chart deploys:
- **Node.js Application**: Main application container with configurable resources and health checks
- **Graphite/StatsD**: Monitoring stack for metrics collection and visualization
- **Ingress**: Optional ingress configuration for external access
- **Persistence**: Configurable storage for Graphite data
- **Security**: Production-ready security contexts and RBAC

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐
│   Ingress       │    │   Application    │
│   (Optional)    │───▶│   (Node.js)      │
└─────────────────┘    └──────────┬───────┘
                                  │
                                  │ StatsD
                                  ▼
                       ┌──────────────────┐
                       │   Graphite       │
                       │   (Monitoring)   │
                       └──────────┬───────┘
                                  │
                                  ▼
                       ┌──────────────────┐
                       │ Persistent       │
                       │ Volume           │
                       └──────────────────┘
```

## 📋 Prerequisites

- Kubernetes cluster (v1.20+)
- Helm 3.0+
- kubectl configured to access your cluster

## 🚀 Installation

### Quick Start

```bash
# Add repository (if external)
helm repo add test-devops <repo-url>
helm repo update

# Install with default values
helm install test-devops ./test-devops

# Or install from repository
helm install test-devops test-devops/test-devops
```

### Environment-Specific Installation

```bash
# Development
helm install test-devops-dev ./test-devops -f values-develop.yaml -n development

# UAT/Staging
helm install test-devops-uat ./test-devops -f values-uat.yaml -n uat

# Production GKE
helm install test-devops-prod ./test-devops -f values-prod-gke.yaml -n production

# Production EKS
helm install test-devops-prod ./test-devops -f values-prod-eks.yaml -n production
```

## ⚙️ Configuration

### Key Configuration Options

| Parameter | Description | Default |
|-----------|-------------|---------|
| `app.replicaCount` | Number of application replicas | `1` |
| `app.image.repository` | Application image repository | `asia-southeast1-docker.pkg.dev/test-devops-478606/test-devops-images/test-devops` |
| `app.image.tag` | Application image tag | `latest` |
| `app.env.nodeEnv` | Node.js environment | `production` |
| `graphite.enabled` | Enable Graphite monitoring | `true` |
| `graphite.persistence.enabled` | Enable persistent storage | `true` |
| `graphite.persistence.size` | Storage size | `10Gi` |
| `ingress.enabled` | Enable ingress | `false` |

### Example values.yaml

```yaml
app:
  replicaCount: 3
  image:
    tag: "v1.2.3"
  env:
    nodeEnv: production
  resources:
    limits:
      cpu: 500m
      memory: 512Mi

graphite:
  persistence:
    enabled: true
    size: 10Gi
    storageClass: "fast-ssd"

ingress:
  enabled: true
  className: "nginx"
  hosts:
    - host: api.example.com
      paths:
        - path: /
          pathType: Prefix
```

## 🌍 Environment-Specific Deployments

### Development Environment (`values-develop.yaml`)

- **Purpose**: Local development and testing
- **Replicas**: 1
- **Resources**: Minimal (100m CPU, 128Mi memory)
- **Storage**: EmptyDir (no persistence)
- **Environment**: `development`
- **Ingress**: Disabled

### UAT Environment (`values-uat.yaml`)

- **Purpose**: User acceptance testing
- **Replicas**: 2 (basic HA)
- **Resources**: Medium (200m CPU, 256Mi memory)  
- **Storage**: 1Gi persistent
- **Environment**: `staging`
- **Ingress**: Disabled

### Production GKE (`values-prod-gke.yaml`)

- **Purpose**: Google Kubernetes Engine production
- **Replicas**: 3 (high availability)
- **Resources**: High (500m CPU, 512Mi memory)
- **Storage**: 10Gi with `standard-rwo` class
- **Environment**: `production`
- **Ingress**: Enabled with GCE ingress class

### Production EKS (`values-prod-eks.yaml`)

- **Purpose**: Amazon Elastic Kubernetes Service production
- **Replicas**: 3 (high availability)
- **Resources**: High (500m CPU, 512Mi memory)
- **Storage**: 10Gi with `gp2` class
- **Environment**: `production`
- **Ingress**: Enabled with ALB ingress class

## 📊 Monitoring

### Graphite Dashboard Access

```bash
# Port forward to access Graphite UI
kubectl port-forward svc/<release-name>-graphite 8080:80

# Open browser
open http://localhost:8080
```

### StatsD Configuration

The application automatically connects to StatsD using:
- **Host**: `<release-name>-graphite`
- **Port**: `8125` (UDP)
- **Protocol**: StatsD

### Metrics Examples

```javascript
// In your Node.js application
const StatsD = require('node-statsd');
const client = new StatsD({
  host: process.env.STATSD_HOST,
  port: process.env.STATSD_PORT
});

// Send metrics
client.increment('api.requests');
client.timing('api.response_time', responseTime);
client.gauge('api.active_users', userCount);
```

## 🔍 Troubleshooting

### Common Issues

#### 1. Pod Startup Issues

```bash
# Check pod status
kubectl get pods -l app.kubernetes.io/instance=<release-name>

# Check logs
kubectl logs -f deployment/<release-name>-app
```

#### 2. Persistent Volume Issues

```bash
# Check PVC status
kubectl get pvc -l app.kubernetes.io/instance=<release-name>

# Describe PVC for events
kubectl describe pvc <release-name>-graphite-data
```

#### 3. Ingress Issues

```bash
# Check ingress status
kubectl get ingress -l app.kubernetes.io/instance=<release-name>

# Check ingress controller logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
```

### Health Checks

```bash
# Application health check
curl http://<app-url>/healthz

# Readiness check
curl http://<app-url>/ready

# Graphite health check
curl http://<graphite-url>/
```

## 🛠️ Development

### Testing Changes

```bash
# Lint the chart
helm lint .

# Test template rendering
helm template test-release . --debug

# Test with specific values
helm template test-release . -f values-develop.yaml

# Dry run installation
helm install test-release . --dry-run --debug
```

### Chart Structure

```
test-devops/
├── Chart.yaml              # Chart metadata
├── values.yaml             # Default configuration
├── values-develop.yaml     # Development environment
├── values-uat.yaml         # UAT environment  
├── values-prod-gke.yaml    # Production GKE
├── values-prod-eks.yaml    # Production EKS
└── templates/
    ├── _helpers.tpl                # Helper templates
    ├── app-deployment.yaml         # Application deployment
    ├── app-service.yaml            # Application service
    ├── graphite-deployment.yaml    # Graphite deployment
    ├── graphite-service.yaml       # Graphite service
    ├── graphite-pvc.yaml           # Persistent volume claim
    ├── ingress.yaml                # Ingress configuration
    ├── serviceaccount.yaml         # Service account
    ├── hpa.yaml                    # Horizontal Pod Autoscaler
    ├── poddisruptionbudget.yaml    # Pod Disruption Budget
    └── NOTES.txt                   # Post-installation notes
```

### Security Features

- **Security Contexts**: Non-root containers with capability dropping
- **RBAC**: Dedicated service account with minimal permissions
- **Network Policies**: Optional network isolation
- **Resource Limits**: CPU and memory limits enforced
- **Health Checks**: Liveness and readiness probes configured

## 📚 Additional Resources

- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Graphite Documentation](https://graphite.readthedocs.io/)
- [StatsD Documentation](https://github.com/statsd/statsd)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `helm lint` and `helm template`
5. Submit a pull request

## 📝 License

This project is licensed under the Apache 2.0 License - see the [LICENSE](LICENSE) file for details.

---

**Happy Deploying!** 🚀