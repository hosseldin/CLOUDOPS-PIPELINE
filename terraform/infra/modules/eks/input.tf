variable "eks_cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
  default     = "eks-cluster"
  
}

variable "eks_version" {
  description = "The version of the EKS cluster"
  type        = string
  default     = "1.28"
  
}


variable "desired_size_node_group" {
  description = "The desired size of the EKS node group"
  type        = number
  default     = 4
  
}

variable "max_size_node_group" {
  description = "The maximum size of the EKS node group"
  type        = number
  default     = 4
  
}

variable "min_size_node_group" {
  description = "The minimum size of the EKS node group"
  type        = number
  default     = 1
  
}

variable "instance_type" {
  description = "The instance type for the EKS node group"
  type        = string
  default     = "t3.medium"
  
}

variable "eks_node_group_name" {
  description = "The name of the EKS node group"
  type        = string
  default     = "eks-node-group"
  
}


variable "region" {
  description = "The AWS region to create the EKS cluster in"
  type = string
  default = "us-east-1"
}



variable "vpc_subnets" {
  description = "The subnets to use for the EKS cluster"
  type = list(string)

}


variable "vpc_id" {
  description = "The VPC ID to use for the EKS cluster"
  type = string
  
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type = string
  
}
