project_id    = "test-devops-478606"
region        = "asia-southeast1"
zone          = "asia-southeast1-a"
cluster_name  = "gke-prod"
network_name  = "prod-network"
subnet_name   = "prod-subnet"
subnet_cidr   = "10.20.0.0/24"
pods_cidr     = "10.200.0.0/16"
services_cidr = "10.201.0.0/16"

# ⚠️ สำหรับ Production ต้องระบุ IP ที่เฉพาะเจาะจง!
# ห้ามใช้ 0.0.0.0/0 ใน production!
office_ip     = "0.0.0.0/0"  # TODO: เปลี่ยนเป็น IP จริง - สำคัญมาก!

environment              = "prod"
enable_private_endpoint  = false  # ตั้งเป็น true ถ้าต้องการ private endpoint อย่างเดียว
regional_cluster         = false  # แนะนำให้เป็น true สำหรับ production (HA)

# Release Channel - ใช้ STABLE สำหรับ production
release_channel          = "STABLE"
maintenance_start_time   = "07:00"  # UTC time

# Monitoring
enable_managed_prometheus = true
enable_binary_authorization = false  # ตั้งเป็น true ถ้าต้องการ security เพิ่มเติม

# System Node Pool
system_node_count  = 2
system_min_nodes   = 2
system_max_nodes   = 5
system_machine_type = "e2-standard-2"

# General Node Pool
general_node_count  = 3
general_min_nodes   = 2
general_max_nodes   = 20
general_machine_type = "e2-standard-4"

# Spot VM Pool - ไม่แนะนำสำหรับ production critical workloads
enable_spot_pool    = false
spot_max_nodes      = 10
spot_machine_type   = "e2-standard-4"
