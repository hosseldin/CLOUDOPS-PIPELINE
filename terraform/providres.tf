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
    key          = "state.tfstate"
    use_lockfile = true
  }
}

provider "aws" {
  region = "us-east-1"
}
