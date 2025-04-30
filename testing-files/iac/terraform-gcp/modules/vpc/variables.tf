# ==============================================
#
# =========== TERRAFORM FILE START =============
#
# ==============================================
#
# Created By: Hossam Mahmoud
# Date: 2025-03-03
# Filename: variables.tf
# Description: 
# Version: 1.0.0
# Copyright (c) 2025 Hossam. All rights reserved.
#
# ==============================================
#
# ====== TERRAFORM IMPLEMENTATION START ======
#
# ==============================================


variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

# Variable for the VPC
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}


variable "aws_region" {
  description = "The AWS region to deploy resources"
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
