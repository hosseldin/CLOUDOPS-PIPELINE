variable "oidc_provider_arn" {
    description = "OIDC provider ARN"
    type        = string

}


variable "cluster_issuer" {
    description = "Cluster issuer URL"
    type        = string
  
}

variable "cluster_name" {
    description = "EKS cluster name"
    type        = string
  
}