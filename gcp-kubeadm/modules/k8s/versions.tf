terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.53.0"
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

provider "google" {
  project = var.gcp_project_id
  region  = "us-central1"
  zone    = "us-central1-c"
}

provider "null" {}

provider "random" {}
