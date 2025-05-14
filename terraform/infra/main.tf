
data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}


module "vpc" {
  source = "./modules/vpc"
}



module "eks" {
  source      = "./modules/eks"
  vpc_subnets = module.vpc.private_subnet_ids
  vpc_id      = module.vpc.vpc_id
  vpc_cidr    = module.vpc.vpc_cidr
}

module "route53" {
  source = "./modules/route53"

}