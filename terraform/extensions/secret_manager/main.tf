# Variables you need:
# - var.region
# - var.oidc_provider_arn
# - var.cluster_issuer (e.g. "https://oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE")

data "aws_iam_policy_document" "external_secrets_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.cluster_issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:external-secrets:external-secrets-sa"]
    }
  }
}

resource "aws_iam_role" "external_secrets_role" {
  name               = "ExternalSecretsOperatorRole"
  assume_role_policy = data.aws_iam_policy_document.external_secrets_assume_role.json
}

resource "aws_iam_policy" "secretsmanager_read" {
  name        = "SecretsManagerReadPolicy"
  description = "Policy for reading secrets from AWS Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "external_secrets_attach" {
  role       = aws_iam_role.external_secrets_role.name
  policy_arn = aws_iam_policy.secretsmanager_read.arn
}

resource "helm_release" "external_secrets_operator" {
  name       = "external-secrets"
  namespace  = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"

  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }
}

resource "kubernetes_service_account" "external_secrets_sa" {
  metadata {
    name      = "external-secrets-sa"
    namespace = "external-secrets"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.external_secrets_role.arn
    }
  }

  depends_on = [
    aws_iam_role.external_secrets_role,
    helm_release.external_secrets_operator
  ]
}

resource "kubernetes_manifest" "cluster_secret_store" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ClusterSecretStore"
    metadata = {
      name = "aws-cluster-secret-store"
    }
    spec = {
      provider = {
        aws = {
          service = "SecretsManager"
          region  = var.region
          auth = {
            serviceAccountRef = {
              name      = kubernetes_service_account.external_secrets_sa.metadata[0].name
              namespace = kubernetes_service_account.external_secrets_sa.metadata[0].namespace
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service_account.external_secrets_sa]
}

resource "kubernetes_manifest" "db_external_secret" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "database-credentials"
      namespace = "argoapp"
    }
    spec = {
      refreshInterval = "1h"
      secretStoreRef = {
        name = "aws-cluster-secret-store"
        kind = "ClusterSecretStore"
      }
      target = {
        name = "database-secret"
      }
      data = [
        {
          secretKey = "username"
          remoteRef = {
            key      = "myapp/database-credentials"
            property = "username"
          }
        },
        {
          secretKey = "password"
          remoteRef = {
            key      = "myapp/database-credentials"
            property = "password"
          }
        }
      ]
    }
  }

  depends_on = [kubernetes_manifest.cluster_secret_store]
}
