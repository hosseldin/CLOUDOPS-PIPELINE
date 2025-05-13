data "http" "alb_controller_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.12.0/docs/install/iam_policy.json"
}

resource "aws_iam_policy" "alb_controller" {
  name   = "AWSLoadBalancerControllerIAMPolicy"
  policy = data.http.alb_controller_policy.response_body
}


data "aws_iam_policy_document" "alb_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.cluster_issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }
  }
}

resource "aws_iam_role" "alb_sa_role" {
  name               = "AmazonEKSLoadBalancerControllerRole"
  assume_role_policy = data.aws_iam_policy_document.alb_assume_role.json
}

resource "aws_iam_role_policy_attachment" "alb_controller_attach" {
  role       = aws_iam_role.alb_sa_role.name
  policy_arn = aws_iam_policy.alb_controller.arn
}



resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

}


resource "kubernetes_service_account" "alb_controller_sa" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.alb_sa_role.arn
    }
  }

  depends_on = [aws_iam_role.alb_sa_role]
}
