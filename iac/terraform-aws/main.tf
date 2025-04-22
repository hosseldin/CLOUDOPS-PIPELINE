# ==============================================
#
# =========== TERRAFORM FILE START =============
#
# ==============================================
#
# Created By: Hossam Mahmoud
# Date: 2025-02-28
# Filename: main.tf
# Description: Calls the networking and compute modules
# Version: 1.0.0
# Copyright (c) 2025 Hossam. All rights reserved.
#
# ==============================================
#
# ====== TERRAFORM IMPLEMENTATION START ======
#
# ==============================================


terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source          = "./modules/vpc"
  igw_name        = var.igw_name
  public_rt_name  = var.public_rt_name
  private_rt_name = var.private_rt_name
  subnets         = var.subnets
  aws_region      = var.aws_region
  vpc_cidr        = var.vpc_cidr
  vpc_name        = var.vpc_name
}

module "security_group" {
  source          = "./modules/security_group"
  vpc_id          = module.vpc.vpc_id
  security_groups = var.security_groups
  ingress_rules   = var.ingress_rules
  egress_rules    = var.egress_rules
}

module "instances" {
  source         = "./modules/instance"
  instances      = var.instances
  subnets        = module.vpc.subnets
  security_group = module.security_group.security-group-id
  ami            = data.aws_ami.ubuntu
}


# ==============================================
#
# ======= TERRAFORM IMPLEMENTATION END ========
#
# ==============================================
#
# End of File
# Copyright (c) 2025 Hossam. All rights reserved.
#
# ==============================================
#
# ============= TERRAFORM FILE END =============
#
# ==============================================
