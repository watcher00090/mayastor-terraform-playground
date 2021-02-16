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
  }
  required_version = ">= 0.13"
}

# TODO: Add some docs about why we are using port 6443
provider "kubernetes" {
  config_path = local.k8s_config
  host        = "https://${google_compute_instance.master.network_interface.0.access_config.0.nat_ip}:6443"
}

provider "google" {
  project = var.gcp_project_id
  region  = "us-central1"
  zone    = "us-central1-c"
}
