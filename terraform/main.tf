module "vpc" {
  source = "./modules/vpc"
}

module "iam" {
  source = "./modules/iam"
  aws_eks_cluster_name = module.eks.cluster_name
}

module "eks" {
  source          = "./modules/eks"
  private_subnets = module.vpc.private_subnet_ids
  cluster_role_arn = module.iam.eks_cluster_role_arn
  node_role_arn    = module.iam.eks_nodes_role_arn
  vpc_id         = module.vpc.vpc_id
  vpc_cidr  = module.vpc.vpc_cidr  
  eks_nodes_role_arn = module.iam.eks_nodes_role_arn
}
