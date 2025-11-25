# GCP Infrastructure Provisioning with Terraform

## 1. Clone the Git Repository
```bash
git clone https://github.com/extosoft-devsecops/test-devops-gitops.git
cd terraform-gke
```

---

## 2. Provisioning Infrastructure for gke-nonprod / gke-prod

### 2.1 Initialize Terraform Dependencies
```bash
make init
```

### 2.2 Preview Infrastructure Changes  
Run this command to preview what Terraform will create or modify.  
`ENV` can be either **nonprod** or **prod**.
```bash
make plan ENV=nonprod
# or
make plan ENV=prod
```

### 2.3 Apply Infrastructure Changes  
This command will apply the Terraform plan. Terraform will ask for confirmation.  
Execution may take **10+ minutes**.
```bash
make apply ENV=nonprod
# or
make apply ENV=prod
```

---

## 3. Destroy Infrastructure  
This deletes **all infrastructure resources** created by Terraform.  
⚠️ **Warning:** This action is irreversible and removes everything.  
Execution may take **10+ minutes**.
```bash
make destroy ENV=nonprod
# or
make destroy ENV=prod
```

---

# Adding gke-nonprod Cluster

## 1. Connect to gke-nonprod Context on Google Cloud Shell

### 1.1 Get Credentials for the Cluster
```bash
gcloud container clusters get-credentials gke-nonprod   --zone asia-southeast1-a   --project test-devops-478606
```

### 1.2 List Available Contexts
```bash
kubectl config get-contexts
```

### 1.3 Switch to the gke-nonprod Context
```bash
kubectl config use-context gke_test-devops-478606_asia-southeast1-a_gke-nonprod
```

---

## 2. Install GitOps Runtime

### 2.1 Validate Cluster Readiness
Run the command provided by GitOps dashboard:
```bash
kubectl get crd | grep -E 'argoproj\.io|sealedsecrets\.bitnami\.com'   && printf "\nERROR: Cluster needs cleaning\nUninstall the projects listed above\n"   || echo "Cluster is clean. It's safe to install the GitOps Runtime"
```

If the terminal outputs **Cluster is clean**, continue to the next step.

### 2.2 Configure Runtime Name and Namespace  
On the GitOps Runtime setup page:
- Enter **Runtime Name**
- Enter **Namespace**
- Click **Generate Token**

Copy **only the command** shown on the screen (not the token).

### 2.3 Install Argo CD Components  
Run the command in Cloud Shell.  
This installs Argo CD and supporting components.  
Installation takes around **3–5 minutes**.

Check pod status:
```bash
kubectl get pods -n codefresh
```

---

# Adding gke-prod Cluster

## 1. Install Codefresh Runtime via Web Console
Go to **Manage Cluster → Add Cluster**.

### Generate an API Token  
Click **Generate Token**, then copy it for later use in step 4.4.

---

## 2. Connect to gke-prod Context in Cloud Shell

### 2.1 Get Credentials
```bash
gcloud container clusters get-credentials gke-prod   --zone asia-southeast1-a   --project test-devops-479012
```

### 2.2 List Contexts
```bash
kubectl config get-contexts
```

### 2.3 Switch to the gke-prod Context
```bash
kubectl config use-context gke_test-devops-479012_asia-southeast1-a_gke-prod
```

---

## 3. Install Codefresh Runtime (CLI)

### 4.1 Download Codefresh CLI
```bash
curl -L --output cf.tgz https://github.com/codefresh-io/cli-v2/releases/latest/download/cf-linux-amd64.tar.gz
tar zxvf cf.tgz
```

### 4.2 Move CLI Binary
```bash
sudo mv ./cf-linux-amd64 /usr/local/bin/cf
```

### 4.3 Verify CLI Installation
```bash
cf version
```

### 4.4 Configure Codefresh API Key
Replace `<YOUR_API_KEY>` with the generated API key.
```bash
cf config create-context codefresh --api-key <YOUR_API_KEY>
```

### 4.5 Add Cluster to Codefresh
```bash
cf cluster add codefresh
```

Select the required context (for example: **a_gke-prod**).  
The CLI will install all required runtime components.

Expected output upon successful installation:
```
Context "gke-test-devops-478606-asia-southeast1-a-gke-prod" created.
STATUS_CODE: 201
deleting token secret csdp-add-cluster-secret-1763792480007
secret "csdp-add-cluster-secret-1763792480007" deleted
=====
cluster gke-test-devops-478606-asia-southeast1-a-gke-prod was added successfully
```

The new cluster will now appear in **Manage Cluster** UI.

---

# Adding Applications (dev, uat, production)

## Step 1 — Create New Application in Codefresh GitOps Apps

- Click **Add Application**
- Set *Application Name*
- Select the correct **Runtime**
- Configure the YAML location

---

## Step 2 — Application Settings

| Setting | Value |
|--------|-------|
| Repository URL | GitOps repo |
| Revision | HEAD or main |
| Path | `helm/app` |
| Cluster | dev/uat = in-cluster, prod = gke-prod |
| Auto-create namespace | Enabled |
| Prune resource | Enabled |
| Self heal | Enabled |
| Server-side apply | Enabled |

Click **Commit** to finalize.

The application will appear in GitOps Apps.  
Wait a moment until the status becomes:

✔ **Synced**  
✔ **Healthy**

**อัปเดตล่าสุด**: วันที่ 24 พฤศจิกายน 2025

