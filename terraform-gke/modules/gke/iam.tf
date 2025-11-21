resource "google_service_account" "gke_nodes" {
  account_id   = "gke-nodes"
  display_name = "GKE Node Service Account"
}

resource "google_project_iam_binding" "node_sa_role" {
  project = var.project_id
  role    = "roles/container.nodeServiceAccount"
  members = ["serviceAccount:${google_service_account.gke_nodes.email}"]
}

output "node_sa" {
  value = google_service_account.gke_nodes.email
}
