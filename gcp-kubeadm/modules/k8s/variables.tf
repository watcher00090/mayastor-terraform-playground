variable "node_count" {}
variable "server_upload_dir" {}
variable "install_packages" {}
variable "hugepages_2M_amount" {}
variable "gcp_project_id" {}
variable "admin_ssh_keys" {}

variable "docker_version" {
  type    = string
  default = "20.10.2"
}
variable "kubernetes_version" {
  type    = string
  default = "1.19.0"
}

variable "gcp_address_cidr_block" {
  type    = string
  default = "10.0.0.0/16"
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

variable "flannel_version" {
  type        = string
  description = "Version of flannel CNI to deploy to the cluster."
  default     = "0.13.0"
}

variable "gcp_instance_type_master" {}

variable "gcp_instance_type_worker" {}

variable "machine_image" {}

variable "kubeconfig_file" {
  type = string
  default = "admin.conf"
}

variable "cluster_name" {
  type = string
  default = "gcp-cluster-1"
}

variable "kubeconfig_dir" {
  type = string
  default = "."
}