module "network" {
  source     = "./modules/network"
  region     = var.region
  project_id = var.project_id

  network_name  = var.network_name
  subnet_name   = var.subnet_name
  subnet_cidr   = var.subnet_cidr
  pods_cidr     = var.pods_cidr
  services_cidr = var.services_cidr
  environment   = var.environment
}

module "gke" {
  source = "./modules/gke"

  project_id   = var.project_id
  region       = var.region
  zone         = var.zone
  cluster_name = var.cluster_name
  environment  = var.environment

  network = module.network.network_name
  subnet  = module.network.subnet_name

  # Secondary IP ranges สำหรับ GKE
  pods_secondary_range_name     = module.network.pods_range_name
  services_secondary_range_name = module.network.services_range_name

  office_ip               = var.office_ip
  enable_private_endpoint = var.enable_private_endpoint
  regional_cluster        = var.regional_cluster
}
