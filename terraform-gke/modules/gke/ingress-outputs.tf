data "kubernetes_service" "nginx_ingress" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }

  depends_on = [google_container_cluster.primary]
}

output "ingress_external_ip" {
  description = "External IP ของ NGINX Ingress Controller"
  value       = try(
    data.kubernetes_service.nginx_ingress.status[0].load_balancer[0].ingress[0].ip,
    "Not available yet"
  )
}