terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.16"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 1.11"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 2.1"
    }
  }
  required_version = ">= 0.13"
}
