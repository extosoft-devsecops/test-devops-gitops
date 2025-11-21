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

