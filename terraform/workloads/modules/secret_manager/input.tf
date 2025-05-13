variable "region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-east-1"
  
}


variable "oidc_provider_arn" {
  description = "The ARN of the OIDC provider for the EKS cluster."
  type        = string
  
}

variable "cluster_issuer" {
  description = "The URL of the cluster issuer."
  type        = string
  
}