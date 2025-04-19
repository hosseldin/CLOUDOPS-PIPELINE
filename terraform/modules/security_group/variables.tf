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

variable "vpc_id" {
  type        = string
  description = "VPC ID to associate the security group with"
}

variable "security_groups" {
  description = "List of security groups with rules"
  type = list(object({
    name        = string
    description = string
  }))
}

variable "ingress_rules" {
  description = "List of ingress rules"
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
