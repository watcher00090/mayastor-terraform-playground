resource "null_resource" "mayastor_dependencies" {
  for_each = var.workers
  # for_each = var.nodes

  connection {
    type        = "ssh"
    host        = each.value
    user        = "root"
    agent       = true
  }

  # NOTE: kernel is tightly correlated with image used for installation. See ../k8s/main.tf search "ubuntu/images"
  # and keep them in sync.
  provisioner "remote-exec" {
    inline = [
      "set -xve",
      "echo ${self.triggers.nr_hugepages} > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages",
      "echo \"vm.nr_hugepages = ${self.triggers.nr_hugepages}\" > /etc/sysctl.d/10-mayastor-hugepages.conf",
      "apt-get -qy update && apt-get -qy install linux-modules-extra-5.8.0-29-generic",
      "echo 'nvme-tcp' >> /etc/modules",
      "systemd-run /bin/sh -c 'sleep 1 && reboot'", # needed to surely get the hugepages right after boot
    ]
  }

  triggers = {
    nr_hugepages = var.nr_hugepages
  }
}

resource "null_resource" "mayastor_dependencies_master" {
  for_each = var.master
  # for_each = var.nodes

  connection {
    type        = "ssh"
    host        = each.value
    user        = "root"
    agent       = true
  }

  # NOTE: kernel is tightly correlated with image used for installation. See ../k8s/main.tf search "ubuntu/images"
  # and keep them in sync.
  provisioner "remote-exec" {
    inline = [
      "set -xve",
      "echo ${self.triggers.nr_hugepages} > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages",
      "echo \"vm.nr_hugepages = ${self.triggers.nr_hugepages}\" > /etc/sysctl.d/10-mayastor-hugepages.conf",
      "apt-get -qy update && apt-get -qy install linux-modules-extra-5.8.0-29-generic",
      "echo 'nvme-tcp' >> /etc/modules",
      "systemd-run /bin/sh -c 'sleep 1 && reboot'", # needed to surely get the hugepages right after boot
    ]
  }

  triggers = {
    nr_hugepages = var.nr_hugepages
  }
}

