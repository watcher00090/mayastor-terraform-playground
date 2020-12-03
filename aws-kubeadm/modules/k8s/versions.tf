terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.15.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 1.13.3"
    }
  }
  required_version = ">= 0.13"
}

provider "aws" {
  region = var.aws_region
}

provider "null" {}

provider "random" {}
