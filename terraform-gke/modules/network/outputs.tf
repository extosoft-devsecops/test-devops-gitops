output "network_name" {
  description = "VPC network name"
  value       = google_compute_network.vpc.name
}

output "network_self_link" {
  description = "Self link of the VPC network"
  value       = google_compute_network.vpc.self_link
}

output "subnet_name" {
  description = "Subnetwork name"
  value       = google_compute_subnetwork.subnet.name
}

output "subnet_self_link" {
  description = "Self link of the subnetwork"
  value       = google_compute_subnetwork.subnet.self_link
}

output "pods_range_name" {
  description = "ชื่อ secondary IP range สำหรับ Pods"
  value       = "pods"
}

output "services_range_name" {
  description = "ชื่อ secondary IP range สำหรับ Services"
  value       = "services"
}

