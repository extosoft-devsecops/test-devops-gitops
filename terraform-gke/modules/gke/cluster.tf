resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.zone

  network    = var.network
  subnetwork = var.subnet

  # Fully Private Node & Control Plane
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false   # ❌ No Public API Access
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  master_authorized_networks_config {
    cidr_blocks {
      display_name = "office"
      cidr_block   = var.office_ip
    }
  }

  # Disable Default Node Pool
  remove_default_node_pool = true
  initial_node_count       = 1

  ip_allocation_policy {}

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
}
