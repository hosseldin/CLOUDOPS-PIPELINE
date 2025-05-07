resource "null_resource" "label_and_taint_node" {
  provisioner "local-exec" {
    command = <<EOT
    NODE=$(kubectl get nodes --selector='!node-role.kubernetes.io/master' -o jsonpath='{.items[0].metadata.name}')
    
    echo "Selected node: $NODE"
    
    # Drain the node (evict pods)
    kubectl drain $NODE --ignore-daemonsets --delete-emptydir-data --force


    # Label and taint the node
    kubectl label nodes $NODE sonarqube=true --overwrite
    kubectl taint nodes $NODE sonarqube=true:NoSchedule --overwrite

    kubectl taint nodes <node-name> sonarqube=true:NoSchedule

    kubectl uncordon $NODE

    EOT
  }
}




resource "kubernetes_namespace" "sonarqube" {
  metadata {
    name = "sonarqube"
  }
}


resource "kubernetes_secret" "monitoring" {
  metadata {
    name      = "sonarqube-monitoring-secret"
    namespace = kubernetes_namespace.sonarqube.metadata[0].name
  }

  data = {
    passcode = base64encode(var.sonarqube_passcode)
  }

  type = "Opaque"

    depends_on = [kubernetes_namespace.sonarqube]
}


resource "helm_release" "sonarqube" {
  name       = "sonarqube"
  namespace  = kubernetes_namespace.sonarqube.metadata[0].name
  repository = "https://SonarSource.github.io/helm-chart-sonarqube"
  chart      = "sonarqube"
  version    = "8.0.0"
  timeout    = 600
  wait       = true

  values = [
    file("./extensions/sonarqube/sonar-values.yaml")
  ]

  
  
  depends_on = [ kubernetes_namespace.sonarqube ]
}


resource "kubernetes_manifest" "sonarqube_ingress" {
  manifest = {
    apiVersion = "networking.k8s.io/v1"
    kind       = "Ingress"
    metadata = {
      name      = "sonarqube-ingress"
      namespace = "sonarqube"
      annotations = {
        "alb.ingress.kubernetes.io/scheme"                   = "internet-facing"
        "alb.ingress.kubernetes.io/group.name"               = "itiproject-alb"
        "alb.ingress.kubernetes.io/target-type"              = "ip"
        "alb.ingress.kubernetes.io/listen-ports"             = "[{\"HTTP\":80}, {\"HTTPS\":443}]"
        "alb.ingress.kubernetes.io/healthcheck-path"         = "/"
        "alb.ingress.kubernetes.io/healthcheck-port"         = "9000"
        "alb.ingress.kubernetes.io/load-balancer-attributes" = "idle_timeout.timeout_seconds=60"
      }
    }
    spec = {
      ingressClassName = "alb"
      tls = [
        {
          hosts = ["sonarqube.itiproject.site"]
        }
      ]
      rules = [
        {
          host = "sonarqube.itiproject.site"
          http = {
            paths = [
              {
                path     = "/"
                pathType = "Prefix"
                backend = {
                  service = {
                    name = "sonarqube-sonarqube"
                    port = {
                      number = 9000
                    }
                  }
                }
              }
            ]
          }
        }
      ]
    }
  }

    depends_on = [ helm_release.sonarqube ]
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

  depends_on = [ kubernetes_manifest.sonarqube_ingress ]

}


data "aws_lb" "sonarqube_alb" {

  tags = {
    "ingress.k8s.aws/stack" = "itiproject-alb"
  }

  depends_on = [ null_resource.wait_for_alb ]

}



resource "aws_route53_record" "sonarqube" {
  zone_id = var.zone_id
  name    = "sonarqube.itiproject.site"
  type    = "A"

  alias {
    name                   = data.aws_lb.sonarqube_alb.dns_name
    zone_id                = data.aws_lb.sonarqube_alb.zone_id
    evaluate_target_health = true
  }
  depends_on = [ data.aws_lb.sonarqube_alb ]
}

