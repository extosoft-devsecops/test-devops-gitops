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
