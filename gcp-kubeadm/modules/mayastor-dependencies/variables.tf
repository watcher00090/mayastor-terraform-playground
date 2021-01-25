variable "nodes" {
  type        = map(string)
  description = "A map of node_name=>_public_ip"
}

variable "master" {
  type = map(string)
  description = "{node_name => public_ip} for the master node"
}

variable "workers" {
  type = map(string)
  description = "A map of worker_node_name=>worker_public_ip"
}

# variable "workers" {
#  type        = map(string)
#  description = "A map of worker_name=>worker_public_ip"
#}

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
