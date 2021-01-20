provider "google" {
  project = var.gcp_project
  region  = "us-central1"
  zone    = "us-central1-c"
}

# TODO: Add some docs about why we are using port 6443
provider "kubernetes" {
  config_path = local.k8s_config
  host        = "https://${google_compute_instance.master.network_interface.0.access_config.0.nat_ip}:6443"
}

locals {
  k8s_config          = upper(var.host_type) == "WINDOWS" ? "${replace(path.module, "///", "\\")}\\secrets\\admin.conf" : "${path.module}/secrets/admin.conf"
  kubeadm_join        = upper(var.host_type) == "WINDOWS" ? "${replace(path.module, "///", "\\")}\\secrets\\kubeadm_join" : "${path.module}/secrets/kubeadm_join"
  windows_module_path = replace(path.module, "///", "\\")
  on_windows_host     = upper(var.host_type) == "WINDOWS" ? true : false
  list_of_ssh_strings = [for entry in var.admin_ssh_keys: "${keys(entry)[0]}:${lookup(values(entry)[0], "key_file", "__missing__") == "__missing__" ? lookup(values(entry)[0], "key_data") : file(lookup(values(entry)[0], "key_file"))}"]
  ssh_keys_string = join("\n", local.list_of_ssh_strings)
}

# Ubuntu 20 LTS
data "google_compute_image" "my_ubuntu_image" {
  # name    = "debian-9-stretch-v20201216"
  # project = "debian-cloud"

  name = "ubuntu-2004-focal-v20210119a"
  project = "ubuntu-os-cloud"   
}

data "google_client_openid_userinfo" "me" {
}

resource "google_compute_project_metadata" "my_ssh_key" {
  metadata = {
    ssh-keys = local.ssh_keys_string
  }
  project = var.gcp_project
}

output "windows_module_path" {
  value       = local.windows_module_path
  description = "windows module path"
}

# self.network_interface.0.access_config.0.nat_ip = ipv4 address of self
resource "google_compute_instance" "master" {
  name         = "master"
  machine_type = "e2-standard-2"
  metadata = {
    block-project-ssh-keys = false
  }
  lifecycle {
    ignore_changes = ["attached_disk"]
  }

  boot_disk {
    initialize_params {
      image = data.google_compute_image.my_ubuntu_image.self_link
    }
  }

  network_interface {
    # default network is created for all GCP projects
    network = "default"
    access_config {

    }
  }

  connection {
    host        = self.network_interface.0.access_config.0.nat_ip
    type        = "ssh"
    user        = "root"
    agent       = true
  }

  # enable root ssh login to instance
  provisioner "local-exec" {
    command = local.on_windows_host ? "${local.windows_module_path}\\scripts\\allow-root-ssh-login.bat" : "${path.module}/scripts/allow-root-ssh-login.sh"
    environment = {
      INSTANCE_IPV4_ADDRESS     = self.network_interface.0.access_config.0.nat_ip
      HELPER_COMMANDS_FILE_PATH = local.on_windows_host ? "${local.windows_module_path}\\files\\helper-commands-root-ssh-login-batch.txt" : "${path.module}/files/helper-commands-root-ssh-login-batch.txt"
      HELPER_COMMANDS_DIRECTORY_PATH = local.on_windows_host ? "${local.windows_module_path}\\files" : "${path.module}/files"
    }
  }

  provisioner "remote-exec" {
    inline = ["set -xve", "mkdir ${var.server_upload_dir}"]
  }

  provisioner "file" {
    source      = "${path.module}/files/10-kubeadm.conf"
    destination = "${var.server_upload_dir}/10-kubeadm.conf"
  }

  provisioner "remote-exec" {
    inline = ["set -xve", "vi ${var.server_upload_dir}/10-kubeadm.conf -c \" set ff=unix | wq\""]
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/bootstrap.sh", {
      docker_version     = var.docker_version,
      install_packages   = var.install_packages,
      kubernetes_version = var.kubernetes_version,
      server_upload_dir  = var.server_upload_dir,
    })
    destination = "${var.server_upload_dir}/bootstrap.sh"
  }

  provisioner "remote-exec" {
    inline = ["set -xve", "vi ${var.server_upload_dir}/bootstrap.sh -c \"set ff=unix | wq\""]
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/master.sh", {
      feature_gates    = var.feature_gates,
      pod_network_cidr = var.pod_network_cidr,
    })
    destination = "${var.server_upload_dir}/master.sh"
  }

  provisioner "remote-exec" {
    inline = ["set -xve", "vi ${var.server_upload_dir}/master.sh -c \"set ff=unix | wq\""]
  }

  provisioner "remote-exec" {
    inline = [
      "set -xve",
      "chmod +x ${var.server_upload_dir}/bootstrap.sh ${var.server_upload_dir}/master.sh",
      "${var.server_upload_dir}/bootstrap.sh",
      "${var.server_upload_dir}/master.sh",
    ]
  }

  provisioner "local-exec" {
    command = local.on_windows_host ? "${local.windows_module_path}\\scripts\\copy-k8s-secrets.bat" : "${path.module}/scripts/copy-k8s-secrets.sh"
    environment = {
      K8S_CONFIG                = local.k8s_config
      KUBEADM_JOIN              = local.kubeadm_join
      SSH_HOST                  = self.network_interface.0.access_config.0.nat_ip
      WINDOWS_MODULE_PATH       = local.windows_module_path
      HELPER_COMMANDS_FILE_PATH = "${local.windows_module_path}\\files\\helper-commands-copy-k8s-secrets-batch.txt"
    }
  }

  depends_on = [google_compute_project_metadata.my_ssh_key]
}

resource "google_compute_instance" "node" {
  count        = var.node_count
  name         = "worker-${count.index + 1}"
  machine_type = "e2-standard-2"
  lifecycle {
    ignore_changes = ["attached_disk"]
  }

  metadata = {
    block-project-ssh-keys = false
  }

  boot_disk {
    initialize_params {
      image = data.google_compute_image.my_ubuntu_image.self_link
    }
  }

  network_interface {
    # default network is created for all GCP projects
    network = "default"
    access_config {

    }
  }

  # enable root ssh login to instance
  provisioner "local-exec" {
    command = local.on_windows_host ? "${local.windows_module_path}\\scripts\\allow-root-ssh-login.bat" : "${path.module}/scripts/allow-root-ssh-login.sh"
    environment = {
      INSTANCE_IPV4_ADDRESS     = self.network_interface.0.access_config.0.nat_ip
      HELPER_COMMANDS_FILE_PATH = "${local.windows_module_path}\\files\\helper-commands-root-ssh-login-batch.txt" 
      HELPER_COMMANDS_DIRECTORY_PATH = local.on_windows_host ? "${local.windows_module_path}\\files" : "${path.module}/files"
    }
  }

  connection {
    host        = self.network_interface.0.access_config.0.nat_ip
    type        = "ssh"
    user        = "root"
    agent       = true
  }

  provisioner "remote-exec" {
    inline = ["mkdir ${var.server_upload_dir}"]
  }

  provisioner "file" {
    source      = "${path.module}/files/10-kubeadm.conf"
    destination = "${var.server_upload_dir}/10-kubeadm.conf"
  }

  provisioner "remote-exec" {
    inline = ["set -xve", "vi ${var.server_upload_dir}/10-kubeadm.conf -c \"set ff=unix | wq\""]
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/bootstrap.sh", {
      docker_version     = var.docker_version,
      install_packages   = var.install_packages,
      kubernetes_version = var.kubernetes_version,
      server_upload_dir  = var.server_upload_dir,
    })
    destination = "${var.server_upload_dir}/bootstrap.sh"
  }

  provisioner "remote-exec" {
    inline = ["set -xve", "vi ${var.server_upload_dir}/bootstrap.sh -c \"set ff=unix | wq\""]
  }

  provisioner "file" {
    source      = local.kubeadm_join
    destination = "${var.server_upload_dir}/kubeadm_join"
  }

  provisioner "remote-exec" {
    inline = ["set -xve", "vi ${var.server_upload_dir}/kubeadm_join -c \"set ff=unix | wq\""]
  }

  provisioner "remote-exec" {
    inline = [
      "set -xve",
      "chmod +x ${var.server_upload_dir}/bootstrap.sh",
      "${var.server_upload_dir}/bootstrap.sh",
      "eval $(cat ${var.server_upload_dir}/kubeadm_join) && systemctl enable docker kubelet",
    ]
  }

  depends_on = [google_compute_instance.master, google_compute_project_metadata.my_ssh_key]
}

#resource "google_ssh_key" "admin_ssh_keys" {
#  for_each   = var.admin_ssh_keys
#  name       = each.key
#  public_key = lookup(each.value, "key_file", "__missing__") == "__missing__" ? lookup(each.value, "key_data") : file(lookup(each.value, "key_file"))
#}


resource "null_resource" "cluster_firewall_master" {
  triggers = {
    deploy_script = templatefile("${path.module}/templates/generate-firewall.sh", {
      k8s_master_ipv4 = google_compute_instance.master.network_interface.0.access_config.0.nat_ip,
      k8s_nodes_ipv4  = join(" ", [for node in google_compute_instance.node : node.network_interface.0.access_config.0.nat_ip]),
      master          = "true",
    }),
    k8s_master_ipv4   = google_compute_instance.master.network_interface.0.access_config.0.nat_ip,
    server_upload_dir = var.server_upload_dir
  }

  connection {
    host        = self.triggers.k8s_master_ipv4
    type        = "ssh"
    user        = "root"
    agent       = true
  }

  provisioner "file" {
    content     = self.triggers.deploy_script
    destination = "${self.triggers.server_upload_dir}/generate-firewall.sh"
  }

  provisioner "remote-exec" {
    inline = ["set -xve", "vi ${var.server_upload_dir}/generate-firewall.sh -c \" set ff=unix | wq\""]
  }

  provisioner "remote-exec" {
    inline = [
      "set -xve",
      "chmod +x ${self.triggers.server_upload_dir}/generate-firewall.sh",
      "${self.triggers.server_upload_dir}/generate-firewall.sh",
    ]
  }

}

# NOTE: null_resource.cluster_firewall is never destroyed (even if terraform does it it stays in effect on infra)
# FIXME: use map instead of setunion in for_each to allow nice naming of firewall resources
resource "null_resource" "cluster_firewall_node" {
  count = var.node_count
  triggers = {
    deploy_script = templatefile("${path.module}/templates/generate-firewall.sh", {
      k8s_master_ipv4 = google_compute_instance.master.network_interface.0.access_config.0.nat_ip,
      k8s_nodes_ipv4  = join(" ", [for node in google_compute_instance.node : node.network_interface.0.access_config.0.nat_ip]),
      master          = "false",
    }),
    k8s_node_ipv4     = google_compute_instance.node[count.index].network_interface.0.access_config.0.nat_ip
    server_upload_dir = var.server_upload_dir
  }

  connection {
    host        = self.triggers.k8s_node_ipv4
    type        = "ssh"
    user        = "root"
    agent       = true
  }

  provisioner "file" {
    content     = self.triggers.deploy_script
    destination = "${self.triggers.server_upload_dir}/generate-firewall.sh"
  }

  provisioner "remote-exec" {
    inline = ["set -xve", "vi ${var.server_upload_dir}/generate-firewall.sh -c \" set ff=unix | wq\""]
  }

  provisioner "remote-exec" {
    inline = [
      "set -xve",
      "chmod +x ${self.triggers.server_upload_dir}/generate-firewall.sh",
      "${self.triggers.server_upload_dir}/generate-firewall.sh",
    ]
  }

}