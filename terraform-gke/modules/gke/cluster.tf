resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.regional_cluster ? var.region : var.zone

  network    = var.network
  subnetwork = var.subnet

  # Private Cluster Configuration
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = var.enable_private_endpoint
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  # Master Authorized Networks - ควรระบุ IP ที่ชัดเจน ไม่ใช่ 0.0.0.0/0
  master_authorized_networks_config {
    cidr_blocks {
      display_name = "office"
      cidr_block   = var.office_ip
    }
  }

  # IP Allocation Policy - ระบุ secondary ranges สำหรับ Pods และ Services
  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name
  }

  # Release Channel - แนะนำให้ใช้ REGULAR
  release_channel {
    channel = var.release_channel
  }

  # Maintenance Window - กำหนดช่วงเวลา maintenance
  maintenance_policy {
    daily_maintenance_window {
      start_time = var.maintenance_start_time
    }
  }

  # Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Network Policy
  network_policy {
    enabled  = false
    # provider = "PROVIDER_UNSPECIFIED" # ใช้ default provider ของ GKE
  }

  # Enable Dataplane V2 (eBPF-based networking)
  datapath_provider = "ADVANCED_DATAPATH"

  # Disable Default Node Pool
  remove_default_node_pool = true
  initial_node_count       = 1

  # Monitoring & Logging Configuration
  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]

    managed_prometheus {
      enabled = var.enable_managed_prometheus
    }
  }

  logging_config {
    enable_components = ["SYSTEM_COMPONENTS"]
  }

  # Binary Authorization (ถ้าต้องการ)
  # binary_authorization {
  #  evaluation_mode = var.enable_binary_authorization ? "PROJECT_SINGLETON_POLICY_ENFORCE" : "DISABLED"
  # }

  # Addons
  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
    network_policy_config {
      disabled = true
    }
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
  }

  # Resource Labels
  resource_labels = {
    environment = var.environment
    managed_by  = "terraform"
  }

  lifecycle {
    prevent_destroy = false # เปลี่ยนเป็น true สำหรับ production
  }
}
