

resource "helm_release" "kube_prometheus_stack" {
  name       = "prometheus"
  namespace  = "monitoring"
  create_namespace = true
  repository =  "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  
  set {
    name  = "prometheus.service.type"
    value = "ClusterIP"
  }

  set {
    name  = "grafana.adminPassword"
    value = "admin"  # For production, replace with a secure password
  }

  set {
    name  = "grafana.service.port"
    value = "80"
  }

  set {
    name  = "grafana.service.targetPort"
    value = "3000"
  }

  set {
    name  = "grafana.service.type"
    value = "ClusterIP"
  }
}

resource "kubernetes_manifest" "grafana_ingress" {
  manifest = {
    apiVersion = "networking.k8s.io/v1"
    kind       = "Ingress"
    metadata = {
      name      = "grafana-ingress"
      namespace = "monitoring"
      annotations = {
        "alb.ingress.kubernetes.io/scheme"               = "internet-facing"
        "alb.ingress.kubernetes.io/target-type"          = "ip"
        "alb.ingress.kubernetes.io/listen-ports"         = "[{\"HTTPS\":443}]"
        "alb.ingress.kubernetes.io/healthcheck-path"     = "/"
        "alb.ingress.kubernetes.io/healthcheck-port"     = "80"
        "alb.ingress.kubernetes.io/load-balancer-attributes" = "idle_timeout.timeout_seconds=60"
        "alb.ingress.kubernetes.io/group.name"           = "itiproject-alb"
        "alb.ingress.kubernetes.io/backend-protocol"     = "HTTP"
        "alb.inggress.kubernetes.io/ssl-redirect"         = "443"
      }
    }
    spec = {
      ingressClassName = "alb"
      tls = [{
        hosts = ["grafana.itiproject.site"]
      }]
      rules = [{
        host = "grafana.itiproject.site"
        http = {
          paths = [{
            path     = "/"
            pathType = "Prefix"
            backend = {
              service = {
                name = "prometheus-grafana"
                port = { number = 80 }
              }
            }
          }]
        }
      }]
    }
  }

  depends_on = [ helm_release.kube_prometheus_stack ]
}
