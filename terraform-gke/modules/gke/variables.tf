variable "project_id" {
  description = "GCP project id"
  type        = string
}

variable "region" {
  description = "Cluster region (or primary location)"
  type        = string
}

variable "zone" {
  description = "Cluster zone (for zonal cluster)"
  type        = string
}

variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
}

variable "network" {
  description = "VPC network name or self link"
  type        = string
}

variable "subnet" {
  description = "Subnetwork name or self link"
  type        = string
}

variable "pods_secondary_range_name" {
  description = "ชื่อ secondary IP range สำหรับ Pods"
  type        = string
  default     = "pods"
}

variable "services_secondary_range_name" {
  description = "ชื่อ secondary IP range สำหรับ Services"
  type        = string
  default     = "services"
}

variable "office_ip" {
  description = "CIDR block allowed to access master (Master Authorized Networks)"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "enable_private_endpoint" {
  description = "เปิด Private Endpoint (ปิด Public Access)"
  type        = bool
  default     = false
}

variable "regional_cluster" {
  description = "สร้าง Regional Cluster แทน Zonal"
  type        = bool
  default     = false
}

variable "node_locations" {
  description = "Zones สำหรับ node pools (สำหรับ regional cluster)"
  type        = list(string)
  default     = []
}

variable "release_channel" {
  description = "GKE Release Channel (RAPID, REGULAR, STABLE)"
  type        = string
  default     = "REGULAR"
}

variable "maintenance_start_time" {
  description = "เวลาเริ่มต้น maintenance window (HH:MM format, UTC)"
  type        = string
  default     = "03:00"
}

variable "enable_managed_prometheus" {
  description = "เปิด Managed Prometheus"
  type        = bool
  default     = true
}

variable "enable_binary_authorization" {
  description = "เปิด Binary Authorization"
  type        = bool
  default     = false
}

# System Node Pool Variables
variable "system_node_count" {
  description = "จำนวน nodes เริ่มต้นสำหรับ system pool"
  type        = number
  default     = 1
}

variable "system_min_nodes" {
  description = "จำนวน nodes ต่ำสุดสำหรับ system pool"
  type        = number
  default     = 1
}

variable "system_max_nodes" {
  description = "จำนวน nodes สูงสุดสำหรับ system pool"
  type        = number
  default     = 3
}

variable "system_machine_type" {
  description = "Machine type สำหรับ system pool"
  type        = string
  default     = "e2-medium"
}

# General Node Pool Variables
variable "general_node_count" {
  description = "จำนวน nodes เริ่มต้นสำหรับ general pool"
  type        = number
  default     = 2
}

variable "general_min_nodes" {
  description = "จำนวน nodes ต่ำสุดสำหรับ general pool"
  type        = number
  default     = 1
}

variable "general_max_nodes" {
  description = "จำนวน nodes สูงสุดสำหรับ general pool"
  type        = number
  default     = 10
}

variable "general_machine_type" {
  description = "Machine type สำหรับ general pool"
  type        = string
  default     = "e2-standard-2"
}

# Spot VM Node Pool Variables
variable "enable_spot_pool" {
  description = "เปิดใช้งาน Spot VM node pool"
  type        = bool
  default     = false
}

variable "spot_max_nodes" {
  description = "จำนวน nodes สูงสุดสำหรับ spot pool"
  type        = number
  default     = 10
}

variable "spot_machine_type" {
  description = "Machine type สำหรับ spot pool"
  type        = string
  default     = "e2-standard-4"
}

variable "node_sa" {
  description = "Service Account for GKE nodes (if not specified, will use the created one)"
  type        = string
  default     = ""
}
