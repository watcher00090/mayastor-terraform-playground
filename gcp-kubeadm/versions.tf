terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 1.11"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 2.1"
    }
    google = {
      source  = "hashicorp/google"
      version = "3.53.0"
    }
  }
  required_version = ">= 0.14"
}

