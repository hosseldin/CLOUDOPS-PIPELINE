# Terraform to deploy Jenkins + Kaniko + Trivy + SonarQube CI/CD Pipeline on EKS

# ------------------------------
# Prerequisites:
# - EKS cluster must already exist
# - You have kubectl configured
# - AWS CLI and eksctl installed
# ------------------------------

# IAM Policy for ECR Access
resource "aws_iam_policy" "ecr_push" {
  name   = "ECRPushPolicy"
  policy = file("./extensions/jenkins/jenkins-ecr-policy.json")
}



data "aws_iam_policy_document" "kaniko_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.cluster_issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:jenkins-ns:kaniko-sa"]
    }
  }
}

resource "aws_iam_role" "kaniko_role" {
  name               = "KanikoECRPushRole"
  assume_role_policy = data.aws_iam_policy_document.kaniko_assume_role.json
}

resource "aws_iam_role_policy_attachment" "kaniko_policy_attach" {
  role       = aws_iam_role.kaniko_role.name
  policy_arn = aws_iam_policy.ecr_push.arn
}

resource "kubernetes_service_account" "kaniko_sa" {
  metadata {
    name      = "kaniko-sa"
    namespace = "jenkins-ns"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.kaniko_role.arn
    }
  }

  depends_on = [aws_iam_role.kaniko_role, helm_release.jenkins]
}



resource "helm_release" "jenkins" {
  name       = "jenkins"
  namespace  = "jenkins-ns"
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  create_namespace = true

}


resource "kubernetes_manifest" "jenkins_ingress" {
  manifest = {
    apiVersion = "networking.k8s.io/v1"
    kind       = "Ingress"
    metadata = {
      name      = "jenkins-ingress"
      namespace = "jenkins-ns"
      annotations = {
        "alb.ingress.kubernetes.io/scheme"                    = "internet-facing"
        "alb.ingress.kubernetes.io/target-type"               = "ip"
        "alb.ingress.kubernetes.io/listen-ports"              = "[{\"HTTPS\":443}]"
        "alb.ingress.kubernetes.io/healthcheck-path"          = "/login"
        "alb.ingress.kubernetes.io/healthcheck-port"          = "8080"
        "alb.ingress.kubernetes.io/load-balancer-attributes"  = "idle_timeout.timeout_seconds=60"
        "alb.ingress.kubernetes.io/group.name"                = "itiproject-alb"
        "alb.ingress.kubernetes.io/backend-protocol"          = "HTTP"
        "alb.ingress.kubernetes.io/ssl-redirect"              = "443"
      }
    }
    spec = {
      ingressClassName = "alb"
      tls = [{
        hosts = ["jenkins.itiproject.site"]
      }]
      rules = [{
        host = "jenkins.itiproject.site"
        http = {
          paths = [{
            path     = "/"
            pathType = "Prefix"
            backend = {
              service = {
                name = "jenkins"
                port = {
                  number = 8080
                }
              }
            }
          }]
        }
      }]
    }
  }

  depends_on = [helm_release.jenkins]
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

  depends_on = [ kubernetes_manifest.jenkins_ingress ]

}


data "aws_lb" "jenkins_alb" {

  tags = {
    "ingress.k8s.aws/stack" = "itiproject-alb"
  }

  depends_on = [ null_resource.wait_for_alb ]

}


resource "aws_route53_record" "jenkins" {
  zone_id = var.zone_id
  name    = "jenkins.itiproject.site"
  type    = "A"

  alias {
    name                   = data.aws_lb.jenkins_alb.dns_name
    zone_id                = data.aws_lb.jenkins_alb.zone_id
    evaluate_target_health = true
  }
  depends_on = [ data.aws_lb.jenkins_alb ]
}

