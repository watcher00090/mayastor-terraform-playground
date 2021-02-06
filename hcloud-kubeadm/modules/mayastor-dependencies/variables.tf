variable "workers" {
  type        = list(any)
  description = "A list of the Mayastor worker nodes"
}

variable "nr_hugepages" {
  type        = number
  description = "Number of 2MB hugepages to allocate on the worker node"
  default     = 640
}

variable "docker_insecure_registry" {
  type        = string
  description = "Set trusted docker registry on worker nodes (handy for private registry)"
  default     = ""
}

variable "k8s_master_ip" {}

variable "num_mayastor_workers" {}
variable "mayastor_worker_node_names" {}
variable "idx_to_mayastor_worker_ip" {}

variable "node_names" {}
variable "idx_to_mount_point" {}
