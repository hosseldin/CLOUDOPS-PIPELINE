# ==============================================
#
# =========== TERRAFORM FILE START =============
#
# ==============================================
#
# Created By: Hossam Mahmoud
# Date: 2025-03-03
# Filename: main.tf
# Description: 
# Version: 1.0.0
# Copyright (c) 2025 Hossam. All rights reserved.
#
# ==============================================
#
# ====== TERRAFORM IMPLEMENTATION START ======
#
# ==============================================

resource "aws_instance" "instances" {
  count = length(var.instances)

  ami           = var.ami.id
  instance_type = var.instances[count.index].instance_type
  subnet_id     = var.subnets["${var.instances[count.index].subnet_name}"].id

  vpc_security_group_ids = [
    for sg in var.instances[count.index].security_group : var.security_group[sg]
    # var.security_group["${var.instances[count.index].security_group}"]

  ]
  tags = {
    Name = var.instances[count.index].name
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
