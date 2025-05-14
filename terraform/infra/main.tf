
data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}


module "vpc" {
  source = "./modules/vpc"
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