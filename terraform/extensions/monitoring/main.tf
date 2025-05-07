

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
    value = ""
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

# Wait until the ALB is available
resource "null_resource" "wait_for_alb" {
  provisioner "local-exec" {
    command = <<EOT
    for i in {1..20}; do
      result=$(aws elbv2 describe-load-balancers --region us-east-1 --query "LoadBalancers[].LoadBalancerArn" --output text)
      for arn in $result; do
        tag_value=$(aws elbv2 describe-tags --resource-arns $arn --region us-east-1 --query "TagDescriptions[0].Tags[?Key=='ingress.k8s.aws/stack'].Value | [0]" --output text)
        if [ "$tag_value" = "itiproject-alb" ]; then
          echo "ALB found with tag: $tag_value"
          exit 0
        fi
      done
      echo "Waiting for ALB to be created..."
      sleep 15
    done
    echo "Timed out waiting for ALB" && exit 1
    EOT
    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [ kubernetes_manifest.grafana_ingress ]
}

data "aws_lb" "grafana_alb" {

  tags = {
    "ingress.k8s.aws/stack" = "itiproject-alb"
  }

  depends_on = [ null_resource.wait_for_alb ]
}


resource "aws_route53_record" "grafana" {
  zone_id = var.zone_id
  name    = "grafana.itiproject.site"
  type    = "A"

  alias {
    name                   = data.aws_lb.grafana_alb.dns_name
    zone_id                = data.aws_lb.grafana_alb.zone_id
    evaluate_target_health = true
  }
  depends_on = [ data.aws_lb.grafana_alb ]
}
