resource "aws_eks_cluster" "eks" {
  name     = var.eks_cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.eks_version

  bootstrap_self_managed_addons = true

  # Enable access entries for authentication
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP" # or "API" for only Access Entries
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    subnet_ids              = var.vpc_subnets
    endpoint_public_access  = true
    endpoint_private_access = true
    # security_group_ids      = [aws_security_group.eks_api.id]
  }

  tags = {
          "alpha.eksctl.io/cluster-oidc-enabled" = "true"
        }
  tags_all = {
          "alpha.eksctl.io/cluster-oidc-enabled" = "true"
        }


  provisioner "local-exec" {
    command = <<EOT
      aws eks update-kubeconfig --name ${self.name} --region ${var.region}
    EOT
  }
}


resource "aws_eks_node_group" "nodes" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = var.eks_node_group_name
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = var.vpc_subnets

  scaling_config {
    desired_size = var.desired_size_node_group
    max_size     = var.max_size_node_group
    min_size     = var.min_size_node_group
  }

  instance_types = [var.instance_type]
}

# resource "aws_security_group" "eks_api" {
#   vpc_id = var.vpc_id

#   ingress {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = [var.vpc_cidr]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"  # all protocols
#     cidr_blocks = ["0.0.0.0/0"]
#     description = "Allow all outbound traffic"
#   }
# }


data "tls_certificate" "eks" {
  url = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}


# Create the IAM OIDC provider for the EKS cluster
resource "aws_iam_openid_connect_provider" "oidc_provider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}
