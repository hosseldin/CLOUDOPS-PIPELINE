terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.57.0" # or a newer version
    }
  }

  backend "s3" {
    bucket       = "terraform-state-project-1"
    region       = "us-east-1"
    key          = "application.tfstate"
    use_lockfile = true
  }
}

provider "aws" {
  region = "us-east-1"
}





provider "kubernetes" {
  host                   = local.cluster_endpoint
  cluster_ca_certificate = base64decode(local.cluster_ca)
  token                  = local.cluster_token
}
