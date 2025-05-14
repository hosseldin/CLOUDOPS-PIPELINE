output "cluster_name" {
  value = aws_eks_cluster.eks.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.eks.endpoint
}

output "cluster_ca" {
  value = aws_eks_cluster.eks.certificate_authority[0].data
}


output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.oidc_provider.arn
}

output "cluster_issuer" {
  value = aws_eks_cluster.eks.identity[0].oidc[0].issuer  
}

output "oidc_provider_url" {
  value = aws_iam_openid_connect_provider.oidc_provider.url
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.eks.endpoint
}