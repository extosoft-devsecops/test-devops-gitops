variable "project_id" {
  description = "GCP project id"
  type        = string
}

variable "region" {
  description = "GCP region for subnet / router / NAT"
  type        = string
}

variable "network_name" {
  description = "VPC network name"
  type        = string
}

variable "subnet_name" {
  description = "Subnetwork name"
  type        = string
}

variable "subnet_cidr" {
  description = "Subnetwork CIDR range"
  type        = string
}

variable "pods_cidr" {
  description = "Secondary IP range สำหรับ Kubernetes Pods"
  type        = string
  default     = "10.100.0.0/16"
}

variable "services_cidr" {
  description = "Secondary IP range สำหรับ Kubernetes Services"
  type        = string
  default     = "10.101.0.0/16"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

