output "cluster_name" {
  description = "GKE cluster name"
  value       = google_container_cluster.primary.name
}

output "cluster_location" {
  description = "GKE cluster location (region / zone)"
  value       = google_container_cluster.primary.location
}

output "cluster_endpoint" {
  description = "GKE master endpoint (internal for private cluster)"
  value       = google_container_cluster.primary.endpoint
}

output "cluster_ca_certificate" {
  description = "GKE cluster CA certificate"
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "workload_identity_pool" {
  description = "Workload Identity pool for the cluster"
  value       = google_container_cluster.primary.workload_identity_config[0].workload_pool
}

output "node_service_account" {
  description = "GCE Service Account used by GKE nodes"
  value       = google_service_account.gke_nodes.email
}
