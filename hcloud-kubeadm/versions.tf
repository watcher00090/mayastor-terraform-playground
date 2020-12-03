terraform {
  required_providers {
    hcloud = {
      source  = "terraform-providers/hcloud"
      version = "~> 1.23.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 1.13.3"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 2.1.2"
    }
  }
  required_version = ">= 0.14"
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "kubernetes" {
  config_path = module.k8s.k8s_admin_conf
  host        = "https://${module.k8s.master_ip}:6443/"
}

provider "null" {}

