variable "subdomains" {
    description = "The subdomain to create the record for"
    type        = list(string)
    default     = [
    "grafana.itiproject.site",
    "jenkins.itiproject.site",
    "sonarqube.itiproject.site",
    "argocd.itiproject.site",
    "www.itiproject.site"
  ]
  
}