# Test DevOps GitOps Repository

A comprehensive GitOps infrastructure repository for managing multi-environment GKE clusters with Terraform, Helm, and ArgoCD.

## Overview

This repository implements a complete GitOps workflow for Google Cloud Platform, managing infrastructure as code and application deployments across multiple environments (nonprod and prod) in separate GCP projects.

## Project Structure

```
.
├── terraform-gke/          # Terraform infrastructure modules
│   ├── env/                # Environment-specific variables
│   ├── modules/            # Reusable Terraform modules
│   │   ├── gke/            # GKE cluster configuration
│   │   └── network/        # VPC network configuration
│   └── *.tf                # Root Terraform configuration
├── helm/                   # Helm charts for applications
│   └── test-devops/        # Application Helm chart
├── resources/              # ArgoCD and Kubernetes resources
│   ├── app-projects/       # ArgoCD app project definitions
│   ├── control-planes/     # Cluster control plane configs
│   └── *.yaml              # Codefresh managed cluster configs
├── runtimes/               # Runtime configurations
└── documents/              # Documentation
```

## Infrastructure Components

### Terraform Modules

**GKE Module** (`terraform-gke/modules/gke/`)
- Google Kubernetes Engine cluster provisioning
- Node pool configuration with autoscaling
- Workload Identity setup
- NGINX Ingress Controller deployment
- IAM role bindings

**Network Module** (`terraform-gke/modules/network/`)
- VPC network creation
- Subnet configuration with secondary IP ranges for GKE
- Cloud NAT setup for private clusters

### Environments

- **NonProd**: `test-devops-478606` (asia-southeast1-a)
  - External IP: 34.126.157.68
- **Prod**: `test-devops-479012` (asia-southeast1-a)
  - External IP: 34.142.135.66

## Prerequisites

- Google Cloud SDK (`gcloud`)
- Terraform >= 1.9
- kubectl
- Helm
- Appropriate GCP permissions for both projects

## Deployment

### Infrastructure Deployment

1. **Initialize Terraform**
   ```bash
   cd terraform-gke
   terraform init -backend-config=backend-nonprod.hcl  # or backend-prod.hcl
   ```

2. **Select Workspace**
   ```bash
   terraform workspace select nonprod  # or prod
   ```

3. **Plan Infrastructure**
   ```bash
   terraform plan -var-file=env/nonprod.tfvars  # or prod.tfvars
   ```

4. **Apply Configuration**
   ```bash
   terraform apply -var-file=env/nonprod.tfvars  # or prod.tfvars
   ```

### Application Deployment

Applications are managed via ArgoCD using the GitOps pattern. Application manifests are located in the `resources/` directory.

## Key Features

- **Multi-Environment Support**: Separate GCP projects for environment isolation
- **NGINX Ingress**: Automatic LoadBalancer provisioning with external IPs
- **Workload Identity**: Secure GCP service access for Kubernetes workloads
- **Modular Design**: Reusable Terraform modules for network and compute
- **State Management**: Remote backend with GCS for Terraform state
- **GitOps Ready**: Structured for ArgoCD-based continuous deployment

## Cross-Project Access

To enable cross-project image pulling from Google Artifact Registry:

```bash
# Grant Artifact Registry Reader role
gcloud projects add-iam-policy-binding test-devops-478606 \
  --member="serviceAccount:PROJECT_NUMBER@compute-system.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.reader"
```

## Troubleshooting

### Ingress Issues
- Verify NGINX controller deployment: `kubectl get pods -n ingress-nginx`
- Check LoadBalancer service: `kubectl get svc -n ingress-nginx`
- Confirm external IP assignment (may take 3-5 minutes)

### Terraform State
- States are isolated per environment in separate workspaces
- Backend configuration stored in `backend-nonprod.hcl` and `backend-prod.hcl`

### Authentication
- NonProd: tossapol.rit146@gmail.com
- Prod: tossapol.rit17@gmail.com

## Contributors

- Wachirawat Chaihanij (wachirawat.c@extosoft.com)
- Tossapol Ritcharoenwattu (tossapol.r@extosoft.com)
