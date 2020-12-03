variable "hcloud_token" {
  type        = string
  description = "HCloud API token. Create a project in https://console.hetzner.cloud - open project -> go to security -> API Tokens and GENERATE API TOKEN. Make sure it is read/write token."
}

variable "hcloud_csi_token" {
  type        = string
  description = "HCloud API token. Create a project in https://console.hetzner.cloud - open project -> go to security -> API Tokens and GENERATE API TOKEN. Make sure it is read/write token. Can be the same as hcloud_token."
}

variable "hetzner_location" {
  type        = string
  description = "Default datacenter to place cloud servers into. Hetzner currently supports hel1, nbg1, fsn1."
  default     = "hel1"
}

variable "node_count" {
  type        = number
  description = "Number of kubernetes worker nodes. Mayastor is deployed in a way that it creates replica on each node."
  default     = 2
}

variable "hugepages_2M_amount" {
  description = "Amount of 2M hugepages to enable system-wide; mayastor requires at least 512 2M hugepages for itself"
  default     = 640
}

variable "admin_ssh_keys" {
  description = "Map of maps for configuring ssh keys. Keys are key names in hcloud values are maps with either key_file which is read or key_data which is used verbatim."
  default = {
    "key1" : { "key_file" = "~/.ssh/id_rsa.pub" },
  }
}

variable "mayastor_use_develop_images" {
  type        = bool
  description = "Deploy 'develop' version of Mayastor instead of latest release. Beware, here be dragons!"
  default     = false
}

variable "server_upload_dir" {
  type        = string
  description = "Terraform provisioner remote-exec sometimes need to put files to a remote machine. It's uploaded into server_upload_dir."
  default     = "/root/tf-upload"
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
