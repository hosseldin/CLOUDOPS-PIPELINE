resource "aws_eks_cluster" "eks" {
  name     = "eks-cluster"
  role_arn = var.cluster_role_arn
  version  = "1.28"

  bootstrap_self_managed_addons = true
  # storage_config {

  # }


  # Enable access entries for authentication
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP" # or "API" for only Access Entries
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    subnet_ids              = var.private_subnets
    endpoint_private_access = true
    endpoint_public_access  = false
    security_group_ids      = [aws_security_group.eks_api.id]
  }

  tags = {
          "alpha.eksctl.io/cluster-oidc-enabled" = "true"
        }
  tags_all = {
          "alpha.eksctl.io/cluster-oidc-enabled" = "true"
        }


  depends_on = [var.cluster_role_arn]
}

resource "aws_eks_node_group" "nodes" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "eks-node-group"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnets

  scaling_config {
    desired_size = 3
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.medium"]
}

resource "aws_security_group" "eks_api" {
  vpc_id = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # all protocols
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
}

# resource "aws_eks_addon" "ebs_csi" {
#   cluster_name = aws_eks_cluster.eks.name
#   addon_name   = "aws-ebs-csi-driver"
#   service_account_role_arn = var.eks_nodes_role_arn
# }


