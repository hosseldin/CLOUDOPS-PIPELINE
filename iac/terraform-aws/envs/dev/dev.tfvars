# ==============================================
#
# =========== TERRAFORM FILE START =============
#
# ==============================================
#
# Created By: Hossam Mahmoud
# Date: 2025-03-04
# Filename: development.tfvars
# Description: 
# Version: 1.0.0
# Copyright (c) 2025 Hossam. All rights reserved.
#
# ==============================================
#
# ====== TERRAFORM IMPLEMENTATION START ======
#
# ==============================================

aws_region = "eu-central-1"
# aws_region = "us-east-1"
vpc_name = "hosa-vpc-terraform"
vpc_cidr = "10.0.0.0/16"

igw_name        = "hosa-igw-01"
public_rt_name  = "hosa-public-rt"
private_rt_name = "hosa-private-rt"

subnets = [
  {
    name       = "hosa-PubSubnet-1"
    cidr_block = "10.0.0.0/24"
    type       = "public"
    az         = "a"
  }
  # {
  #   name       = "hosa-PubSubnet-2"
  #   cidr_block = "10.0.1.0/24"
  #   type       = "public"
  #   az         = "a"
  # }
]


instances = [
  {
    name           = "hosa-server-1"
    subnet_name    = "hosa-PubSubnet-1"
    instance_type  = "t3.micro"
    security_group = ["public-sg"]
  }
]

# , "prometheus-sg"

security_groups = [
  {
    name        = "public-sg"
    description = "Allow public access"
  },
  {
    name        = "prometheus-sg"
    description = "Allow public access"
  }
  # {
  #   name        = "private-sg"
  #   description = "Allow private access"
  # }
]


ingress_rules = [
  {
    security_group_name = "public-sg"
    from_port           = 22
    to_port             = 22
    protocol            = "tcp"
    cidr_blocks         = ["0.0.0.0/0"]
  },
  {
    security_group_name = "prometheus-sg"
    from_port           = 9100
    to_port             = 9100
    protocol            = "tcp"
    cidr_blocks         = ["217.53.81.238/32"]
  }
  # {
  #   security_group_name = "private-sg"
  #   from_port           = 22
  #   to_port             = 22
  #   protocol            = "tcp"
  #   cidr_blocks         = ["10.0.0.0/16"]
  # }
]


egress_rules = [
  {
    security_group_name = "public-sg"
    from_port           = 80
    to_port             = 80
    protocol            = "tcp"
    cidr_blocks         = ["0.0.0.0/0"]
  },
  {
    security_group_name = "prometheus-sg"
    from_port           = 80
    to_port             = 80
    protocol            = "tcp"
    cidr_blocks         = ["0.0.0.0/0"]
  }
]




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
