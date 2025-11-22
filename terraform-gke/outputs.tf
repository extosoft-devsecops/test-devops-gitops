output "cluster_name" {
  description = "GKE Cluster name"
  value       = module.gke.cluster_name
}

output "cluster_location" {
  description = "GKE Cluster location (region หรือ zone)"
  value       = module.gke.cluster_location
}

output "cluster_endpoint" {
  description = "GKE Cluster endpoint (API server)"
  value       = module.gke.cluster_endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "GKE Cluster CA certificate"
  value       = module.gke.cluster_ca_certificate
  sensitive   = true
}

output "network_name" {
  description = "VPC Network name"
  value       = module.network.network_name
}

output "subnet_name" {
  description = "Subnet name"
  value       = module.network.subnet_name
}

output "node_service_account" {
  description = "Service Account ที่ใช้โดย GKE nodes"
  value       = module.gke.node_service_account
}

output "kubectl_connect_command" {
  description = "คำสั่งสำหรับ connect kubectl กับ cluster"
  value       = "gcloud container clusters get-credentials ${module.gke.cluster_name} --zone=${module.gke.cluster_location} --project=${var.project_id}"
}

output "ingress_external_ip" {
  description = "NGINX Ingress Controller External IP"
  value       = module.gke.ingress_external_ip
}