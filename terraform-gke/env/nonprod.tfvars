project_id    = "test-devops-478606"
region        = "asia-southeast1"
zone          = "asia-southeast1-a"
cluster_name  = "gke-nonprod"
network_name  = "nonprod-network"
subnet_name   = "nonprod-subnet"
subnet_cidr   = "10.10.0.0/24"
pods_cidr     = "10.100.0.0/16"
services_cidr = "10.101.0.0/16"

# ⚠️ ควรเปลี่ยนเป็น IP ของ office หรือ VPN จริง
# ตัวอย่าง: "203.154.1.1/32" หรือ "1.2.3.4/32"
office_ip     = "0.0.0.0/0"  # TODO: เปลี่ยนเป็น IP จริง!

environment              = "nonprod"
enable_private_endpoint  = false
regional_cluster         = false

# Release Channel
release_channel          = "REGULAR"
maintenance_start_time   = "03:00"

# Monitoring
enable_managed_prometheus = true
enable_binary_authorization = false

# System Node Pool
system_node_count  = 1
system_min_nodes   = 1
system_max_nodes   = 3
system_machine_type = "e2-medium"

# General Node Pool
general_node_count  = 1
general_min_nodes   = 1
general_max_nodes   = 5
general_machine_type = "e2-standard-2"

# Spot VM Pool (สำหรับประหยัดค่าใช้จ่าย)
enable_spot_pool    = true
spot_max_nodes      = 5
spot_machine_type   = "e2-standard-2"
