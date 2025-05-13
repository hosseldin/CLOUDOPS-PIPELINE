
data "aws_caller_identity" "current" {

}

data "aws_eks_cluster" "cluster" {
  name = "${var.cluster_name}"
}

data "aws_eks_cluster_auth" "cluster" {
  name = "${var.cluster_name}"
}


data "aws_iam_openid_connect_provider" "oidc_provider" {
  url = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}


data "aws_route53_zone" "main" {
  name         = "${var.domain_name}"
}


locals {
  cluster_endpoint = data.aws_eks_cluster.cluster.endpoint
  cluster_token = data.aws_eks_cluster_auth.cluster.token
  cluster_ca = data.aws_eks_cluster.cluster.certificate_authority[0].data
  account_id = data.aws_caller_identity.current.account_id
  zone_id = data.aws_route53_zone.main.zone_id
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
        "argocd-image-updater.argoproj.io/image-list"                         = "my-image=${local.account_id}.dkr.ecr.${var.image_region}.amazonaws.com/${var.image_name}"
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

    depends_on = [kubernetes_namespace.argoapp]
}




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

  depends_on = [ kubernetes_manifest.my_app ]
}





data "aws_lb" "app_alb" {

  tags = {
    "ingress.k8s.aws/stack" = "itiproject-alb"
  }

  depends_on = [ null_resource.wait_for_alb ]

}


resource "aws_route53_record" "app" {
  zone_id = local.zone_id
  name    = "www.itiproject.site"
  type    = "A"

  alias {
    name                   = data.aws_lb.app_alb.dns_name
    zone_id                = data.aws_lb.app_alb.zone_id
    evaluate_target_health = true
  }
  depends_on = [ data.aws_lb.app_alb ]
}
