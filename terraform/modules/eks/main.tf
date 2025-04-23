resource "aws_eks_cluster" "eks" {
  name     = "eks-cluster"
  role_arn = var.cluster_role_arn
  version  = "1.27"

  vpc_config {
    subnet_ids = var.private_subnets
    endpoint_private_access = true
    endpoint_public_access  = false
    security_group_ids = [aws_security_group.eks_api.id]

  }

  

  depends_on = [
    var.cluster_role_arn
  ]
}

resource "aws_eks_node_group" "nodes" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "eks-node-group"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnets

  scaling_config {
    desired_size = 2
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