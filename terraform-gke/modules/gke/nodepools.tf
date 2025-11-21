resource "google_container_node_pool" "system" {
  cluster    = google_container_cluster.primary.name
  location   = var.zone
  name       = "system-pool"
  node_count = 2

  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }

  node_config {
    machine_type    = "e2-medium"
    service_account = google_service_account.gke_nodes.email
    disk_type       = "pd-standard"
    disk_size_gb    = 20
    labels = { pool = "system" }
    tags   = ["system"]
  }
}

