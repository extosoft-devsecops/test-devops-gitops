variable "project_id" {
  description = "GCP project id"
  type        = string
}

variable "region" {
  description = "Cluster region (or primary location)"
  type        = string
}

variable "zone" {
  description = "Cluster region (or primary location)"
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

variable "office_ip" {
  description = "CIDR block allowed to access master (Master Authorized Networks)"
  type        = string
}

variable "node_sa" {
  description = "Service Account for GKE nodes (if not specified, will use the created one)"
  type        = string
  default     = ""
}
