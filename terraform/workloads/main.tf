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
  cluster_name = data.aws_eks_cluster.cluster.name
  cluster_endpoint = data.aws_eks_cluster.cluster.endpoint
  cluster_token = data.aws_eks_cluster_auth.cluster.token
  cluster_ca = data.aws_eks_cluster.cluster.certificate_authority[0].data
  cluster_issuer = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
  account_id = data.aws_caller_identity.current.account_id
  oidc_provider_arn = data.aws_iam_openid_connect_provider.oidc_provider.arn

  zone_id = data.aws_route53_zone.main.zone_id
}


module "load_balancer" {
  source = "./modules/load_balancer"
  cluster_issuer = local.cluster_issuer
  oidc_provider_arn = local.oidc_provider_arn
  cluster_name = local.cluster_name
}



module "monitoring" {
  source = "./modules/monitoring"
  zone_id = local.zone_id
  depends_on = [ module.load_balancer ]
  
}






module "jenkins" {
  source = "./modules/jenkins"
  zone_id = local.zone_id
  cluster_issuer = local.cluster_issuer
  oidc_provider_arn = local.oidc_provider_arn
  cluster_name = local.cluster_name

  depends_on = [ module.load_balancer ]
}




module "argocd" {
  source = "./modules/argocd"
  zone_id = local.zone_id
  cluster_issuer = local.cluster_issuer
  oidc_provider_arn = local.oidc_provider_arn
  cluster_name = local.cluster_name
  account_id = local.account_id
  sshPrivateKey_path = "./modules/argocd/id_rsa"
  depends_on = [ module.load_balancer ]
}

module "sonarqube" {
  source = "./modules/sonarqube"
  zone_id = local.zone_id

  depends_on = [ module.load_balancer ]
  
}

# module "external_secrets" {
#   source = "./modules/secret_manager"
#   region = "us-east-1"
#   oidc_provider_arn = local.oidc_provider_arn
#   cluster_issuer = local.cluster_issuer
#   depends_on = [ module.eks, module.iam, module.vpc, module.load_balancer ]
  
# }


