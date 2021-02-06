resource "null_resource" "mayastor_dependencies" {
  count = var.num_mayastor_workers

  connection {
    type = "ssh"
    host = jsondecode(self.triggers.mayastor_worker_ips)[count.index]
  }

  # NOTE: kernel is tightly correlated with image used for installation. See ../k8s/main.tf search "ubuntu/images"
  # and keep them in sync.
  provisioner "remote-exec" {
    inline = [
      "set -xve",
      "echo \"${self.triggers.nr_hugepages}\" > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages",
      "echo \"vm.nr_hugepages = ${self.triggers.nr_hugepages}\" > /etc/sysctl.d/10-mayastor-hugepages.conf",
      "apt-get -qy update && apt-get -qy install linux-modules-extra-5.8.0-29-generic",
      "echo 'nvme-tcp' >> /etc/modules",
      "systemd-run /bin/sh -c 'sleep 1 && reboot'", # needed to surely get the hugepages right after boot
    ]
  }

  triggers = {
    nr_hugepages = var.nr_hugepages
    mayastor_worker_ips = jsonencode(var.idx_to_mayastor_worker_ip)
  }
}

// Set label openebs.io/engine=mayastor on all mayastor worker nodes - we want to run MSN on all mayastor worker nodes
resource "null_resource" "mayastor_node_label" {
  count = var.num_mayastor_workers
  triggers = {
    k8s_master_ip = var.k8s_master_ip
    mayastor_worker_node_names = jsonencode(var.mayastor_worker_node_names)
  }
  connection {
    host = self.triggers.k8s_master_ip
  }
  provisioner "remote-exec" {
    inline = ["kubectl label node ${jsondecode(self.triggers.mayastor_worker_node_names)[count.index]} openebs.io/engine=mayastor"]
  }
  provisioner "remote-exec" {
    when   = destroy
    inline = ["kubectl label node ${jsondecode(self.triggers.mayastor_worker_node_names)[count.index]} openebs.io/engine-"]
  }
}





resource "null_resource" "debug" {
  depends_on = [null_resource.mayastor_node_label]
  provisioner "local-exec" {
    command = <<EOF
      echo '===================================================' >>  ~/.mayastor_dependencies_var_dump
      echo 'docker_insecure_registry=${jsonencode(var.docker_insecure_registry)}' >> ~/.mayastor_dependencies_var_dump
      echo 'k8s_master_ip=${jsonencode(var.k8s_master_ip)}'  >> ~/.mayastor_dependencies_var_dump
      echo 'num_mayastor_workers=${jsonencode(var.num_mayastor_workers)}' >> ~/.mayastor_dependencies_var_dump
      echo 'mayastor_worker_node_names=${jsonencode(var.mayastor_worker_node_names)}' >> ~/.mayastor_dependencies_var_dump
      echo 'idx_to_mayastor_worker_ip=${jsonencode(var.idx_to_mayastor_worker_ip)}' >> ~/.mayastor_dependencies_var_dump
      echo 'node_names=${jsonencode(var.node_names)}' >> ~/.mayastor_dependencies_var_dump
      echo 'idx_to_mount_point=${jsonencode(var.idx_to_mount_point)}' >> ~/.mayastor_dependencies_var_dump
    EOF
  }
}