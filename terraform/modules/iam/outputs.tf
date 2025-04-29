output "eks_cluster_role_arn" {
  value = aws_iam_role.eks_cluster.arn
}

output "eks_nodes_role_arn" {
  value = aws_iam_role.eks_nodes.arn
}


output "ecr_full_access_arn" {
  value = aws_iam_policy.ecr_full_access.arn
  
}