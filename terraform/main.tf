
data "aws_caller_identity" "current" {}


module "vpc" {
  source = "./modules/vpc"
}

module "iam" {
  source               = "./modules/iam"
  aws_eks_cluster_name = module.eks.cluster_name
}

module "eks" {
  source             = "./modules/eks"
  private_subnets    = module.vpc.private_subnet_ids
  cluster_role_arn   = module.iam.eks_cluster_role_arn
  node_role_arn      = module.iam.eks_nodes_role_arn
  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = module.vpc.vpc_cidr
  eks_nodes_role_arn = module.iam.eks_nodes_role_arn
}

module "route53" {
  source = "./modules/route53"
  
}



module "load_balancer" {
  source = "./extensions/load_balancer"
  cluster_issuer = module.eks.cluster_issuer
  oidc_provider_arn = module.eks.oidc_provider_arn
  cluster_name = module.eks.cluster_name
  depends_on = [ module.eks, module.iam, module.vpc ]
}



module "monitoring" {
  source = "./extensions/monitoring"
  zone_id = module.route53.zone_id
  depends_on = [ module.eks, module.iam, module.vpc, module.load_balancer, module.route53 ]
  
}


module "jenkins" {
  source = "./extensions/jenkins"
  zone_id = module.route53.zone_id
  cluster_issuer = module.eks.cluster_issuer
  oidc_provider_arn = module.eks.oidc_provider_arn
  cluster_name = module.eks.cluster_name

  depends_on = [ module.eks, module.iam, module.vpc, module.load_balancer, module.route53 ]
}

module "argocd" {
  source = "./extensions/argocd"
  zone_id = module.route53.zone_id
  cluster_issuer = module.eks.cluster_issuer
  oidc_provider_arn = module.eks.oidc_provider_arn
  cluster_name = module.eks.cluster_name
  account_id = data.aws_caller_identity.current.account_id
  sshPrivateKey_path = "./extensions/argocd/id_rsa"
  depends_on = [ module.eks, module.iam, module.vpc, module.load_balancer, data.aws_caller_identity.current, module.route53 ] 
}