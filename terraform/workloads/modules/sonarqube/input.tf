variable "sonarqube_passcode" {
    description = "SonarQube passcode for authentication"
    type        = string
    sensitive   = true
    default     = "123456789"
  
}


variable "zone_id" {
  description = "The ID of the Route 53 hosted zone."
  type        = string
  
}