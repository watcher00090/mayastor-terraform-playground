variable "workers" {
  type        = map(string)
  description = "A map of worker_name=>worker_public_ip"
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
