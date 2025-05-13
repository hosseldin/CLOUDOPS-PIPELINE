

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  chart      = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  namespace  = "argocd"
  depends_on = [kubernetes_namespace.argocd]
}

resource "kubernetes_manifest" "argocd_ingress" {
  manifest = {
    apiVersion = "networking.k8s.io/v1"
    kind       = "Ingress"
    metadata = {
      name      = "argocd-ingress"
      namespace = "argocd"
      annotations = {
        "alb.ingress.kubernetes.io/scheme"                    = "internet-facing"
        "alb.ingress.kubernetes.io/target-type"               = "ip"
        "alb.ingress.kubernetes.io/listen-ports"              = "[{\"HTTPS\":443}]"
        "alb.ingress.kubernetes.io/backend-protocol"          = "HTTPS"
        "alb.ingress.kubernetes.io/ssl-redirect"              = "443"
        "alb.ingress.kubernetes.io/healthcheck-path"          = "/"
        "alb.ingress.kubernetes.io/healthcheck-port"          = "443"
        "alb.ingress.kubernetes.io/load-balancer-attributes"  = "idle_timeout.timeout_seconds=60"
        "alb.ingress.kubernetes.io/group.name"                = "itiproject-alb"
      }
    }
    spec = {
      ingressClassName = "alb"
      tls = [{
        hosts = ["argocd.itiproject.site"]
      }]
      rules = [{
        host = "argocd.itiproject.site"
        http = {
          paths = [{
            path     = "/"
            pathType = "Prefix"
            backend = {
              service = {
                name = "argocd-server"
                port = {
                  number = 443
                }
              }
            }
          }]
        }
      }]
    }
  }

  depends_on = [helm_release.argocd, kubernetes_namespace.argocd]
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

  depends_on = [ kubernetes_manifest.argocd_ingress ]
}

data "aws_lb" "argocd_alb" {

  tags = {
    "ingress.k8s.aws/stack" = "itiproject-alb"
  }

  depends_on = [ null_resource.wait_for_alb ]
}


resource "aws_route53_record" "argocd" {
  zone_id = var.zone_id
  name    = "argocd.itiproject.site"
  type    = "A"

  alias {
    name                   = data.aws_lb.argocd_alb.dns_name
    zone_id                = data.aws_lb.argocd_alb.zone_id
    evaluate_target_health = true
  }
  depends_on = [ data.aws_lb.argocd_alb ]
}



data "aws_iam_policy_document" "image_updater_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(var.cluster_issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:argocd:argocd-image-updater"]
    }
  }
}

resource "aws_iam_role" "image_updater_role" {
  name               = "ArgoCDImageUpdaterRole"
  assume_role_policy = data.aws_iam_policy_document.image_updater_assume_role.json
}

resource "aws_iam_role_policy_attachment" "image_updater_attach" {
  role       = aws_iam_role.image_updater_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "kubernetes_service_account" "image_updater_sa" {
  metadata {
    name      = "argocd-image-updater"
    namespace = "argocd"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.image_updater_role.arn
    }
  }

  depends_on = [aws_iam_role.image_updater_role, kubernetes_namespace.argocd]
}



data "template_file" "image_updater_yaml" {
  template = file("${path.module}/image-updater-values.tpl.yaml")

  vars = {
    account_id = var.account_id
    region     = var.region
  }
}



resource "helm_release" "argocd_image_updater" {
  name       = "argocd-image-updater"
  chart      = "argocd-image-updater"
  repository = "https://argoproj.github.io/argo-helm"
  namespace  = "argocd"

  values = [
    data.template_file.image_updater_yaml.rendered
  ]
  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.image_updater_sa.metadata[0].name
  }

  depends_on = [kubernetes_service_account.image_updater_sa, kubernetes_namespace.argocd]
}






data "local_file" "private_key" {
  filename   = var.sshPrivateKey_path
}

resource "kubernetes_secret" "git_creds" {
  depends_on = [data.local_file.private_key, kubernetes_namespace.argocd]

  metadata {
    name      = "git-creds"
    namespace = "argocd"
  }

  data = {
    sshPrivateKey = data.local_file.private_key.content
  }

  type = "Opaque"
}



resource "kubernetes_namespace" "argoapp" {
  metadata {
    name = "argoapp"
  }
}



resource "kubernetes_manifest" "my_app" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "my-app"
      namespace = "argocd"
      annotations = {
        "argocd-image-updater.argoproj.io/image-list"                         = "my-image=${var.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.image_name}"
        "argocd-image-updater.argoproj.io/my-image.update-strategy"          = "newest-build"
        "argocd-image-updater.argoproj.io/my-image.allow-tags"               = "regexp:^v.*"
        "argocd-image-updater.argoproj.io/write-back-method"                = "git:secret:argocd/git-creds"
        "argocd-image-updater.argoproj.io/write-back-target"                = "helmvalues:/k8s/values.yaml"
        "argocd-image-updater.argoproj.io/my-image.helm.image-spec"         = "image.tag"
        "argocd-image-updater.argoproj.io/git-repository"                   = "git@github.com:mina-safwat-1/test_argo.git"
        "argocd-image-updater.argoproj.io/git-branch"                       = "main"
      }
    }
    spec = {
      destination = {
        namespace = "argoapp"
        server    = "https://kubernetes.default.svc"
      }
      source = {
        repoURL        = "https://github.com/mina-safwat-1/test_argo.git"
        path           = "k8s"
        targetRevision = "HEAD"
      }
      project = "default"
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = [
          "Validate=true",
          "CreateNamespace=false",
          "PrunePropagationPolicy=foreground",
          "PruneLast=true"
        ]
      }
    }
  }

    depends_on = [kubernetes_secret.git_creds, helm_release.argocd_image_updater, helm_release.argocd, kubernetes_namespace.argoapp]
}






data "aws_lb" "app_alb" {

  tags = {
    "ingress.k8s.aws/stack" = "itiproject-alb"
  }

  depends_on = [ null_resource.wait_for_alb ]

}


resource "aws_route53_record" "app" {
  zone_id = var.zone_id
  name    = "www.itiproject.site"
  type    = "A"

  alias {
    name                   = data.aws_lb.app_alb.dns_name
    zone_id                = data.aws_lb.app_alb.zone_id
    evaluate_target_health = true
  }
  depends_on = [ data.aws_lb.app_alb ]
}
