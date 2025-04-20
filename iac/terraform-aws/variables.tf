# ==============================================
#
# =========== TERRAFORM FILE START =============
#
# ==============================================
#
# Created By: Hossam Mahmoud
# Date: 2025-03-02
# Filename: variables.tf
# Description: Variables for reusability and maintainability
# Version: 1.0.0
# Copyright (c) 2025 Hossam. All rights reserved.
#
# ==============================================
#
# ====== TERRAFORM IMPLEMENTATION START ======
#
# ==============================================

variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
}


variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

# Variable for the VPC
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "subnets" {
  type = list(object({
    name       = string
    cidr_block = string
    type       = string
    az         = string
  }))
}

variable "igw_name" {
  type        = string
  description = "Name of the Internet Gateway"
}

variable "public_rt_name" {
  type        = string
  description = "Name of the Public Route Table"
}

variable "private_rt_name" {
  type        = string
  description = "Name of the Private Route Table"
}

variable "instances" {
  type = list(object({
    name           = string
    subnet_name    = string
    instance_type  = string
    security_group = list(string)
  }))
}


# variable "vpc_id" {
#   type        = string
#   description = "VPC ID to associate the security group with"
# }

variable "security_groups" {
  description = "List of security groups"
  type = list(object({
    name        = string
    description = string
  }))
}

variable "ingress_rules" {
  description = "List of ingress rules for security groups"
  type = list(object({
    security_group_name = string
    from_port           = number
    to_port             = number
    protocol            = string
    cidr_blocks         = list(string)
  }))
}

variable "egress_rules" {
  type = list(object({
    security_group_name = string
    from_port           = number
    to_port             = number
    protocol            = string
    cidr_blocks         = list(string)
  }))
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
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
