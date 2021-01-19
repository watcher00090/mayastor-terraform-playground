variable "node_count" {}
variable "server_upload_dir" {}
variable "install_packages" {}
variable "hugepages_2M_amount" {}
variable "gcp_project" {}
variable "ssh_public_key_name_for_instances" {}
variable "host_type" {}

variable "docker_version" {
  type    = string
  default = "20.10.2"
}
variable "kubernetes_version" {
  type    = string
  default = "1.19.0"
}


variable "feature_gates" {
  description = "Add Feature Gates e.g. 'DynamicKubeletConfig=true'"
  default     = ""
}


variable "pod_network_cidr" {
  default = "10.244.0.0/16"
}

variable "metrics_server_version" {
  default = "0.3.7"
}