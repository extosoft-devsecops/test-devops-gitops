.PHONY: help init plan apply destroy validate fmt clean

ENV ?= nonprod
TFVARS_FILE = env/$(ENV).tfvars

help: ## แสดงคำสั่งที่ใช้ได้
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

init: ## Initialize Terraform
	terraform init

validate: ## Validate Terraform configuration
	terraform validate

fmt: ## Format Terraform files
	terraform fmt -recursive

plan: ## Plan infrastructure changes (ENV=nonprod|prod)
	terraform plan -var-file=$(TFVARS_FILE)

apply: ## Apply infrastructure changes (ENV=nonprod|prod)
	terraform apply -var-file=$(TFVARS_FILE)

destroy: ## Destroy infrastructure (ENV=nonprod|prod)
	terraform destroy -var-file=$(TFVARS_FILE)

show: ## Show current state
	terraform show

output: ## Show outputs
	terraform output

clean: ## Clean Terraform cache
	rm -rf .terraform/
	rm -f .terraform.lock.hcl

# สำหรับ Production - ต้อง confirm
prod-plan: ## Plan for production
	@echo "⚠️  Planning for PRODUCTION environment..."
	@terraform plan -var-file=env/prod.tfvars

prod-apply: ## Apply to production (requires confirmation)
	@echo "⚠️  WARNING: Applying to PRODUCTION environment!"
	@read -p "Are you sure? (yes/no): " confirm && [ "$$confirm" = "yes" ] || (echo "Aborted."; exit 1)
	terraform apply -var-file=env/prod.tfvars

# Connect to cluster
connect-nonprod: ## Connect kubectl to nonprod cluster
	gcloud container clusters get-credentials gke-nonprod --zone=asia-southeast1-a --project=test-devops-478606

connect-prod: ## Connect kubectl to prod cluster
	gcloud container clusters get-credentials gke-prod --zone=asia-southeast1-a --project=test-devops-478606

# GCS Backend setup
setup-backend: ## Setup GCS backend bucket
	@echo "Creating GCS bucket for Terraform state..."
	gsutil mb -p test-devops-478606 -l asia-southeast1 gs://test-devops-terraform-state || echo "Bucket already exists"
	gsutil versioning set on gs://test-devops-terraform-state
	@echo "Backend bucket ready!"

# Enable required GCP APIs
enable-apis: ## Enable required GCP APIs
	gcloud services enable container.googleapis.com
	gcloud services enable compute.googleapis.com
	gcloud services enable servicenetworking.googleapis.com
	gcloud services enable cloudresourcemanager.googleapis.com

# Security check
security-check: ## Check for security issues
	@echo "Checking for security issues..."
	@grep -r "0.0.0.0/0" env/*.tfvars && echo "⚠️  WARNING: Found 0.0.0.0/0 in tfvars - please fix!" || echo "✅ No 0.0.0.0/0 found"

# Cost estimate (requires infracost)
cost: ## Estimate infrastructure cost
	@which infracost > /dev/null || (echo "Install infracost first: https://www.infracost.io/docs/"; exit 1)
	infracost breakdown --path . --terraform-var-file=$(TFVARS_FILE)

