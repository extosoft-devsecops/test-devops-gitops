# Install NGINX Ingress Controller
resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.10.1"
  namespace  = "ingress-nginx"
  
  create_namespace = true
  
  values = [
    yamlencode({
      controller = {
        service = {
          type = "LoadBalancer"
          loadBalancerSourceRanges = ["0.0.0.0/0"]
        }
        metrics = {
          enabled = true
          serviceMonitor = {
            enabled = false
          }
        }
        replicaCount = var.environment == "prod" ? 3 : 2
        resources = {
          requests = {
            cpu    = "100m"
            memory = "90Mi"
          }
          limits = {
            cpu    = "200m"
            memory = "256Mi"
          }
        }
        nodeSelector = {
          "cloud.google.com/gke-nodepool" = "system-pool"
        }
        tolerations = [
          {
            key      = "CriticalAddonsOnly"
            operator = "Exists"
          }
        ]
      }
    })
  ]
  
  depends_on = [
    google_container_node_pool.system
  ]
}

# Wait for LoadBalancer IP to be assigned
resource "time_sleep" "wait_for_lb" {
  depends_on = [helm_release.nginx_ingress]
  
  create_duration = "60s"
}