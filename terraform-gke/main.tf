module "network" {
  source       = "./modules/network"
  region       = var.region
  project_id   = var.project_id

  network_name = var.network_name
  subnet_name  = var.subnet_name
  subnet_cidr  = var.subnet_cidr
}

module "gke" {
  source      = "./modules/gke"

  project_id   = var.project_id
  region       = var.region
  zone         = var.zone
  cluster_name = var.cluster_name

  network     = module.network.network_name
  subnet      = module.network.subnet_name

  office_ip   = var.office_ip
}
