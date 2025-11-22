# Temporarily disable ingress data source for new clusters
# data "kubernetes_service" "nginx_ingress" {
#   metadata {
#     name      = "ingress-nginx-controller"
#     namespace = "ingress-nginx"
#   }
#
#   depends_on = [google_container_cluster.primary]
# }

output "ingress_external_ip" {
  description = "External IP ของ NGINX Ingress Controller"
  value       = "Ingress controller not installed yet"
}