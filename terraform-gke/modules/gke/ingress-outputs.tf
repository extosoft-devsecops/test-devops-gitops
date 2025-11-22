# Get NGINX Ingress Controller LoadBalancer IP
data "kubernetes_service" "nginx_ingress" {
  metadata {
    name      = "nginx-ingress-ingress-nginx-controller"
    namespace = "ingress-nginx"
  }

  depends_on = [
    helm_release.nginx_ingress,
    time_sleep.wait_for_lb
  ]
}

output "ingress_external_ip" {
  description = "External IP ของ NGINX Ingress Controller"
  value       = try(
    data.kubernetes_service.nginx_ingress.status.0.load_balancer.0.ingress.0.ip,
    "IP not assigned yet"
  )
}