variable "private_subnets" {
  type = list(string)
}

variable "cluster_role_arn" {
  type = string
}

variable "node_role_arn" {
  type = string
}


variable "vpc_id" {
  type = string
  
}

variable "vpc_cidr" {
  type = string
  
}

variable "eks_nodes_role_arn" {
 type = string 
}


variable "region" {
  type = string
  default = "us-east-1"
  
}