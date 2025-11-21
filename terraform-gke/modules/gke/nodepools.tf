resource "google_container_node_pool" "system" {
  cluster    = google_container_cluster.primary.name
  location   = var.regional_cluster ? var.region : var.zone
  name       = "system-pool"

  # Node count - สำหรับ zonal cluster
  node_count = var.regional_cluster ? null : var.system_node_count

  # Node locations - สำหรับ multi-zone
  node_locations = var.regional_cluster ? var.node_locations : null

  # Initial node count - สำหรับ regional cluster
  initial_node_count = var.regional_cluster ? var.system_node_count : null

  # Autoscaling
  autoscaling {
    min_node_count = var.system_min_nodes
    max_node_count = var.system_max_nodes
  }

  # Management - Auto upgrade & Auto repair
  management {
    auto_upgrade = true
    auto_repair  = true
  }

  # Upgrade Settings
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
    strategy        = "SURGE"
  }

  # Node Configuration
  node_config {
    machine_type    = var.system_machine_type
    service_account = google_service_account.gke_nodes.email
    disk_type       = "pd-standard"
    disk_size_gb    = 50
    image_type      = "COS_CONTAINERD"

    labels = {
      pool        = "system"
      environment = var.environment
    }

    tags = ["gke-node", "${var.cluster_name}-node"]

    # Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Shielded Instance Config
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    # OAuth Scopes
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

# General Workload Node Pool
resource "google_container_node_pool" "general" {
  cluster    = google_container_cluster.primary.name
  location   = var.regional_cluster ? var.region : var.zone
  name       = "general-pool"

  node_count         = var.regional_cluster ? null : var.general_node_count
  node_locations     = var.regional_cluster ? var.node_locations : null
  initial_node_count = var.regional_cluster ? var.general_node_count : null

  autoscaling {
    min_node_count = var.general_min_nodes
    max_node_count = var.general_max_nodes
  }

  management {
    auto_upgrade = true
    auto_repair  = true
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
    strategy        = "SURGE"
  }

  node_config {
    machine_type    = var.general_machine_type
    service_account = google_service_account.gke_nodes.email
    disk_type       = "pd-standard"
    disk_size_gb    = 100
    image_type      = "COS_CONTAINERD"

    labels = {
      pool        = "general"
      environment = var.environment
    }

    tags = ["gke-node", "${var.cluster_name}-node"]

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

# Spot VM Node Pool (Optional - สำหรับ cost optimization)
resource "google_container_node_pool" "spot" {
  count = var.enable_spot_pool ? 1 : 0

  cluster    = google_container_cluster.primary.name
  location   = var.regional_cluster ? var.region : var.zone
  name       = "spot-pool"

  node_count         = var.regional_cluster ? null : 0
  node_locations     = var.regional_cluster ? var.node_locations : null
  initial_node_count = var.regional_cluster ? 0 : null

  autoscaling {
    min_node_count = 0
    max_node_count = var.spot_max_nodes
  }

  management {
    auto_upgrade = true
    auto_repair  = true
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
    strategy        = "SURGE"
  }

  node_config {
    machine_type    = var.spot_machine_type
    service_account = google_service_account.gke_nodes.email
    disk_type       = "pd-standard"
    disk_size_gb    = 100
    image_type      = "COS_CONTAINERD"
    spot            = true  # Spot VM

    labels = {
      pool        = "spot"
      environment = var.environment
      workload    = "batch"
    }

    # Taint เพื่อให้ใช้เฉพาะ workload ที่ tolerate spot instances
    taint {
      key    = "cloud.google.com/gke-spot"
      value  = "true"
      effect = "NO_SCHEDULE"
    }

    tags = ["gke-node", "${var.cluster_name}-node", "spot"]

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

