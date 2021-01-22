variable "gcp_project" {
  type        = string
  description = "The GCP project that all of your resources will be created in."
  # default = "default"
}

#variable "gcp_token" {
#  type        = string
#  description = "GCP API token." #TODO add description of how to make this token here
#}

#variable "gcp_region" {
#  type        = string
#  description = "Default region to place VM instances into."
#  default     = "us-central1"
#}

#variable "gcp_zone" {
#  type        = string
#  description = "Zone within the region to place VM instances into"
#  default     = "us-central1-c"
#}


variable "node_count" {
  type        = number
  description = "Number of kubernetes worker nodes. Mayastor is deployed in a way that it creates replica on each node."
  default     = 4
}

variable "hugepages_2M_amount" {
  description = "Amount of 2M hugepages to enable system-wide; mayastor requires at least 512 2M hugepages for itself"
  default     = 640
}

variable "host_type" {
  type        = string
  description = "The type of host being used locally. Currently accepts only Linux, Windows, and OSX. Case insensitive."
  validation {
    condition     = contains(["WINDOWS", "LINUX", "OSX"], upper(var.host_type))
    error_message = "Error, invalid host type. Only accepts Windows, Linux, and OSX. Please try again. Case insensitive."
  }
}

variable "admin_ssh_keys" {
  type = map(map(string))
  description = "Map of maps for configuring public SSH keys for the project. Keys are key names in GCP, values are maps containing either the key 'key_data' associated with the contents of the public key, or 'key_file' associated with an absolute path to the public key file."
}

variable "mayastor_use_develop_images" {
  type        = bool
  description = "Deploy 'develop' version of Mayastor instead of latest release. Beware, here be dragons!"
  default     = false
}

variable "server_upload_dir" {
  type        = string
  description = "Terraform provisioner remote-exec sometimes need to put files onto a remote machine. It's uploaded into server_upload_dir."
  default     = "~/tf-upload"
}

variable "install_packages" {
  type        = list(string)
  description = "Additional deb packages to install during instance bootstrap."
  default = [
    "fio",
    "iotop",
    "nvme-cli",
    "strace",
    "sysstat",
    "tcpdump",
  ]
}

variable "deploy_mayastor" {
  type        = bool
  description = "Deploy mayastor itself. Set to false to skip."
  default     = true
}

# Note: cannot use null as a default as validation doesn't like it
variable "mayastor_replicas" {
  type        = number
  default     = -1
  description = "How many replicas should mayastor default storageclass use? Leave default to use mayastor_replicas == number of cluster nodes. For mayastor_replicas > number of cluster nodes mayastor **will not start**."
  validation {
    condition     = var.mayastor_replicas == -1 || var.mayastor_replicas >= 1
    error_message = "The mayastor_replicas must be greater or equal to 1."
  }
}

variable "docker_insecure_registry" {
  type        = string
  description = "Set trusted docker registry on worker nodes (handy for private registry)"
  default     = ""
}
