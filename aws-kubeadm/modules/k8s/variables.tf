// Example:
// {
//   "key1" : { "key_file" = "~/.ssh/id_ed25519.pub" },
//   "key2" : { "key_data" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMQCA+Slye+ZcgLRxdIyQCpEcG/XKKwyxpRWuCSpS098 email@example.com" },
// }
variable "ssh_public_keys" {
  type        = map(map(string))
  description = "Map of maps of public ssh keys."
}

variable "kubeconfig_dir" {
  type        = string
  description = "Directory on the local machine in which to save the kubeconfig file of the created cluster. The basename of the kubeconfig file will consist of the cluster name followed by \".conf\", for example, \"my-cluster.conf\". The directory may be specified as an absolute or relative path. The directory must exist, otherwise an error occurs. By default, the current working directory is used."
  default     = "."
}

variable "kubeconfig_file" {
  type        = string
  description = "**This is an optional variable with a default value of null**. The exact filename as which to save the kubeconfig file of the crated cluster on the local machine. The filename may be specified as an absolute or relative path. The parent directory of the filename must exist, otherwise an error occurs. If a file with the same name already exists, it will be overwritten. If this variable is set to a value other than null, the value of the \"kubeconfig_dir\" variable is ignored."
  default     = null
}

variable "allowed_ssh_cidr_blocks" {
  type        = list(string)
  description = "List of CIDR blocks from which it is allowed to make SSH connections to the EC2 instances that form the cluster nodes. By default, SSH connections are allowed from everywhere."
  default     = ["0.0.0.0/0"]
}

variable "allowed_k8s_cidr_blocks" {
  type        = list(string)
  description = "List of CIDR blocks from which it is allowed to make Kubernetes API request to the API server of the cluster. By default, Kubernetes API requests are allowed from everywhere. Note that Kubernetes API requests from Pods and nodes inside the cluster are always allowed, regardless of the value of this variable."
  default     = ["0.0.0.0/0"]
}

variable "aws_instance_type_master" {
  type        = string
  description = "EC2 instance type for the master node (must have at least 2 CPUs)."
  default     = "t3.medium"
}

variable "aws_instance_type_worker" {
  type        = string
  description = "EC2 instance type for the worker nodes."
}

variable "num_workers" {
  type        = number
  description = "Number of worker nodes."
  default     = 2
}

variable "num_mayastor_workers" {
  type        = number
  description = "Number of Mayastor worker nodes."
  default     = 2
}

variable "tags" {
  type        = map(string)
  description = "A set of tags to assign to the created AWS resources. These tags will be assigned in addition to the default tags. The default tags include \"terraform-kubeadm:cluster\" which is assigned to all resources and whose value is the cluster name, and \"terraform-kubeadm:node\" which is assigned to the EC2 instances and whose value is the name of the Kubernetes node that this EC2 corresponds to."
  default     = {}
}

variable "aws_region" {
  type        = string
  description = "AWS region in which to create the cluster."
  default     = "eu-central-1"
}

variable "flannel_version" {
  type        = string
  description = "Version of flannel CNI to deploy to the cluster."
}

variable "aws_vpc_cidr_block" {
  type        = string
  description = "CIDR block to use for AWS VPC network addresses."
  default     = "10.0.0.0/16"
}

variable "cluster_name" {
  type        = string
  description = "Name of the cluster. Used as a part of AWS names and tags of various cluster components."
}

variable "docker_version" {
  type        = string
  description = "Docker version to install."
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version to install."
}

variable "ebs_volume_size" {
  type        = number
  description = "Additional EBS volume size to attach to EC2 instance on workers in gigabytes."
}

variable "mayastor_use_develop_images" {
  type        = bool
  description = "Use 'develop' tag for mayastor images instead of 'latest' (selects different EC2 instance)."
}

variable "install_packages" {
  type        = list(any)
  description = "Additional deb packages to install during instance bootstrap."
  default = [
    "fio",
    "iotop",
    "nvme-cli",
    "strace",
    "sysstat",
    "tcpdump",
    "nfs-common",
  ]
}

variable "aws_instance_root_size_gb" {}

# NOTE: instance must have >2 CPUs to support mayastor deployment
variable "aws_worker_instances" {
}

variable "use_worker_instances_spec" {}
variable "worker_instances_spec" {}
variable "worker_instances_spec_default_num_workers_per_type" {}

variable "use_old_style_worker_names" {}