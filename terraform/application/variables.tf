variable "cluster_name" {

    description = "The name of the EKS cluster"
    type        = string
    default     = "eks-cluster"
  
}


variable "domain_name" {
    description = "The domain name for the load balancer"
    type        = string
    default     = "itiproject.site"
  
}


variable "image_region" {
    description = "The region of the image repository"
    type        = string
    default     = "us-east-1"
  
}

variable "image_name" {
    description = "The name of the Docker image to be updated."
    type        = string
    default     = "node-app-jenkins"
  
}