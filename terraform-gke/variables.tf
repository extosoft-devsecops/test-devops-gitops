variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region สำหรับ resources"
  type        = string
  default     = "asia-southeast1"
}

variable "zone" {
  description = "GCP Zone สำหรับ GKE cluster (zonal) หรือ primary zone (regional)"
  type        = string
  default     = "asia-southeast1-a"
}

variable "network_name" {
  description = "ชื่อ VPC Network"
  type        = string
}

variable "subnet_name" {
  description = "ชื่อ Subnet"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR range สำหรับ subnet หลัก"
  type        = string
  validation {
    condition     = can(cidrhost(var.subnet_cidr, 0))
    error_message = "subnet_cidr ต้องเป็น CIDR notation ที่ถูกต้อง เช่น 10.10.0.0/24"
  }
}

variable "pods_cidr" {
  description = "Secondary CIDR range สำหรับ Pods"
  type        = string
  default     = "10.100.0.0/16"
}

variable "services_cidr" {
  description = "Secondary CIDR range สำหรับ Services"
  type        = string
  default     = "10.101.0.0/16"
}

variable "cluster_name" {
  description = "ชื่อ GKE Cluster"
  type        = string
}

variable "office_ip" {
  description = "CIDR block ที่อนุญาตให้เข้าถึง GKE Control Plane (Master Authorized Networks)"
  type        = string

  validation {
    condition     = can(cidrhost(var.office_ip, 0))
    error_message = "office_ip ต้องเป็น CIDR notation ที่ถูกต้อง เช่น 203.154.1.1/32"
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod", "nonprod"], var.environment)
    error_message = "environment ต้องเป็น dev, staging, prod หรือ nonprod"
  }
}

variable "enable_private_endpoint" {
  description = "เปิด Private Endpoint (ปิด Public Access ไปยัง Control Plane สนิท)"
  type        = bool
  default     = false
}

variable "regional_cluster" {
  description = "สร้าง Regional Cluster แทน Zonal (HA สูงกว่า แต่แพงกว่า)"
  type        = bool
  default     = false
}

variable "system_machine_type" {
  type        = string
  description = "Machine type for system node pool"
  default     = "e2-medium"
}

variable "general_node_count" {
  type        = number
  description = "Node count for general node pool"
  default     = 1
}

variable "general_machine_type" {
  type        = string
  description = "Machine type for general node pool"
  default     = "e2-standard-2"
}

variable "release_channel" {
  type        = string
  description = "GKE release channel (RAPID, REGULAR, STABLE)"
  default     = "REGULAR"

  validation {
    condition     = contains(["RAPID", "REGULAR", "STABLE", "UNSPECIFIED"], var.release_channel)
    error_message = "release_channel ต้องเป็น RAPID, REGULAR, STABLE หรือ UNSPECIFIED"
  }
}

variable "maintenance_start_time" {
  type        = string
  description = "Maintenance window start time (HH:MM format in UTC)"
  default     = "03:00"

  validation {
    condition     = can(regex("^([0-1][0-9]|2[0-3]):[0-5][0-9]$", var.maintenance_start_time))
    error_message = "maintenance_start_time ต้องอยู่ในรูปแบบ HH:MM เช่น 03:00"
  }
}

variable "system_node_count" {
  type        = number
  description = "Node count for system node pool"
  default     = 1
}

variable "system_min_nodes" {
  type        = number
  description = "Min nodes for system node pool autoscaler"
  default     = 1
}

variable "system_max_nodes" {
  type        = number
  description = "Max nodes for system node pool autoscaler"
  default     = 3
}

variable "general_min_nodes" {
  type        = number
  description = "Min nodes for general node pool autoscaler"
  default     = 1
}

variable "general_max_nodes" {
  type        = number
  description = "Max nodes for general node pool autoscaler"
  default     = 5
}

variable "enable_spot_pool" {
  type        = bool
  description = "Enable spot VM node pool for cost savings"
  default     = false
}

variable "spot_max_nodes" {
  type        = number
  description = "Max nodes for spot VM node pool"
  default     = 5
}

variable "spot_machine_type" {
  type        = string
  description = "Machine type for spot VM node pool"
  default     = "e2-standard-2"
}

variable "enable_binary_authorization" {
  type        = bool
  description = "Enable Binary Authorization for the cluster"
  default     = false
}

variable "enable_managed_prometheus" {
  type        = bool
  description = "Enable Cloud Managed Prometheus for the cluster"
  default     = false
}