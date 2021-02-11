locals {
  k8s_config          = "${path.module}/secrets/admin.conf"
  kubeadm_join        = "${path.module}/secrets/kubeadm_join"
  dummy_user_name     = "ubuntu-admin"
  list_of_ssh_strings = [for key in keys(var.admin_ssh_keys) : "${key}:${lookup(var.admin_ssh_keys[key], "key_file", "__missing__") == "__missing__" ? lookup(var.admin_ssh_keys[key], "key_data") : file(lookup(var.admin_ssh_keys[key], "key_file"))}"]
  extra_ssh_string    = "${local.dummy_user_name}:${lookup(var.admin_ssh_keys[keys(var.admin_ssh_keys)[0]], "key_file", "__missing__") == "__missing__" ? lookup(var.admin_ssh_keys[keys(var.admin_ssh_keys)[0]], "key_data") : file(lookup(var.admin_ssh_keys[keys(var.admin_ssh_keys)[0]], "key_file"))}"
  ssh_keys_string     = join("\n", local.list_of_ssh_strings)
  flannel_cidr        = "10.244.0.0/16"
}

# Ubuntu 20 LTS
data "google_compute_image" "my_ubuntu_image" {
  name    = "ubuntu-2004-focal-v20210119a"
  project = "ubuntu-os-cloud"
}

resource "google_compute_project_metadata" "ssh_keys" {
  metadata = {
    ssh-keys = join("\n", [local.ssh_keys_string, local.extra_ssh_string])
  }
  project    = var.gcp_project
}

# self.network_interface.0.access_config.0.nat_ip = ipv4 address of self
resource "google_compute_instance" "master" {
  name         = "master"
  machine_type = var.gcp_instance_type_master
  # machine_type = "n2-standard-2"
  metadata = {
    block-project-ssh-keys = false
  }
  lifecycle {
    ignore_changes = [attached_disk]
  }
  //sudo sed -i 's/PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config
  metadata_startup_script = <<EOF
sudo systemctl restart ssh
  EOF

  boot_disk {
    initialize_params {
      image = data.google_compute_image.my_ubuntu_image.self_link
    }
  }


  network_interface {
    subnetwork = google_compute_subnetwork.main.name
    # could also use 'network = "default"'
    access_config {

    }
  }

  connection {
    host  = self.network_interface.0.access_config.0.nat_ip
    type  = "ssh"
    user  = "root"
    agent = true
  }

  # enable root ssh login to instance
  /*
  provisioner "local-exec" {
    command = "chmod +x ${path.module}/scripts/allow-root-ssh-login.sh && ${path.module}/scripts/allow-root-ssh-login.sh"
    environment = {
      INSTANCE_IPV4_ADDRESS          = self.network_interface.0.access_config.0.nat_ip
      HELPER_COMMANDS_FILE_PATH      = "${path.module}/templates/helper-commands-root-ssh-login-batch.txt"
      HELPER_COMMANDS_DIRECTORY_PATH = "${path.module}/files"
      USER_NAME                      = local.dummy_user_name
    }
  }
  */

  provisioner "remote-exec" {
    inline = ["set -xve", "mkdir ${var.server_upload_dir}"]
  }

  provisioner "file" {
    source      = "${path.module}/templates/10-kubeadm.conf"
    destination = "${var.server_upload_dir}/10-kubeadm.conf"
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/bootstrap.sh", {
      docker_version     = var.docker_version,
      install_packages   = var.install_packages,
      kubernetes_version = var.kubernetes_version,
      server_upload_dir  = var.server_upload_dir,
      node_name = "master"
    })
    destination = "${var.server_upload_dir}/bootstrap.sh"
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/master.sh", {
      feature_gates               = var.feature_gates,
      pod_network_cidr            = local.flannel_cidr,
      master_public_ipv4_address  = self.network_interface.0.access_config.0.nat_ip,
      master_private_ipv4_address = self.network_interface.0.network_ip
    })
    destination = "${var.server_upload_dir}/master.sh"
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
    command = "chmod +x ${path.module}/scripts/copy-k8s-secrets.sh && ${path.module}/scripts/copy-k8s-secrets.sh"
    environment = {
      K8S_CONFIG                = local.k8s_config
      KUBEADM_JOIN              = local.kubeadm_join
      SSH_HOST                  = self.network_interface.0.access_config.0.nat_ip
    }
  }

  depends_on = [google_compute_project_metadata.ssh_keys, google_compute_firewall.allow_egress, google_compute_firewall.allow_internal_traffic, google_compute_firewall.allow_internal_traffic_pods]
}

resource "google_compute_instance" "node" {
  count = var.node_count
  name  = "worker-${count.index + 1}"
  # machine_type = "n2-standard-2"
  machine_type = var.gcp_instance_type_worker
  lifecycle {
    ignore_changes = [attached_disk]
  }

  metadata_startup_script = <<EOF
sudo sed -i 's/PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config
sudo systemctl restart ssh
  EOF

  metadata = {
    block-project-ssh-keys = false
  }

  boot_disk {
    initialize_params {
      image = data.google_compute_image.my_ubuntu_image.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.main.name
    # network = "default"
    access_config {

    }
  }

  # enable root ssh login to instance
  /*
  provisioner "local-exec" {
    command = local.on_windows_host ? "${local.windows_module_path}\\scripts\\allow-root-ssh-login.bat" : "chmod +x ${path.module}/scripts/allow-root-ssh-login.sh && ${path.module}/scripts/allow-root-ssh-login.sh"
    environment = {
      INSTANCE_IPV4_ADDRESS          = self.network_interface.0.access_config.0.nat_ip
      HELPER_COMMANDS_FILE_PATH      = "${local.windows_module_path}\\templates\\helper-commands-root-ssh-login-batch.txt"
      HELPER_COMMANDS_DIRECTORY_PATH = local.on_windows_host ? "${local.windows_module_path}\\templates" : "${path.module}/files"
      USER_NAME                      = local.dummy_user_name
    }
  }
  */

  connection {
    host  = self.network_interface.0.access_config.0.nat_ip
    type  = "ssh"
    user  = "root"
    agent = true
  }

  provisioner "remote-exec" {
    inline = ["mkdir ${var.server_upload_dir}"]
  }

  provisioner "file" {
    source      = "${path.module}/templates/10-kubeadm.conf"
    destination = "${var.server_upload_dir}/10-kubeadm.conf"
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/bootstrap.sh", {
      docker_version     = var.docker_version,
      install_packages   = var.install_packages,
      kubernetes_version = var.kubernetes_version,
      server_upload_dir  = var.server_upload_dir,
      node_name = "worker-${count.index}"
    })
    destination = "${var.server_upload_dir}/bootstrap.sh"
  }

  provisioner "file" {
    source      = local.kubeadm_join
    destination = "${var.server_upload_dir}/kubeadm_join"
  }

  provisioner "remote-exec" {
    inline = [
      "set -xve",
      "chmod +x ${var.server_upload_dir}/bootstrap.sh",
      "${var.server_upload_dir}/bootstrap.sh",
      "eval $(cat ${var.server_upload_dir}/kubeadm_join) && systemctl enable docker kubelet",
    ]
  }

  depends_on = [google_compute_instance.master, google_compute_project_metadata.ssh_keys]
}

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
    host  = self.triggers.k8s_master_ipv4
    type  = "ssh"
    user  = "root"
    agent = true
  }

  provisioner "file" {
    content     = self.triggers.deploy_script
    destination = "${self.triggers.server_upload_dir}/generate-firewall.sh"
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
    host  = self.triggers.k8s_node_ipv4
    type  = "ssh"
    user  = "root"
    agent = true
  }

  provisioner "file" {
    content     = self.triggers.deploy_script
    destination = "${self.triggers.server_upload_dir}/generate-firewall.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "set -xve",
      "chmod +x ${self.triggers.server_upload_dir}/generate-firewall.sh",
      "${self.triggers.server_upload_dir}/generate-firewall.sh",
    ]
  }
}

resource "null_resource" "flannel" {
  # well ... FIXME?
  # I like to have flannel removable/upgradeable via TF, but stuff required to SSH to the instance for destroy is destroyed before flannel :-/
  depends_on = [google_compute_instance.master, google_compute_subnetwork.main]
  triggers = {
    host            = google_compute_instance.master.network_interface.0.access_config.0.nat_ip # public ipv4
    flannel_version = var.flannel_version
  }
  connection {
    host  = self.triggers.host
    agent = true
    type  = "ssh"
  }

  // NOTE: admin.conf is copied to ubuntu's home by kubeadm module
  provisioner "remote-exec" {
    inline = [
      "kubectl apply -f \"https://raw.githubusercontent.com/coreos/flannel/v${self.triggers.flannel_version}/Documentation/kube-flannel.yml\""
    ]
  }

  # FIXME: deleting flannel's yaml isn't enough to undeploy it completely (e.g. /etc/cni/net.d/*, ...)
  provisioner "remote-exec" {
    when = destroy
    inline = [
      "kubectl delete -f \"https://raw.githubusercontent.com/coreos/flannel/v${self.triggers.flannel_version}/Documentation/kube-flannel.yml\""
    ]
  }
}
