provider "google" {
    project = var.gcp_project
    region = "us-central1"
    zone = "us-central1-c"
}

resource "google_compute_instance" "master" {
    name = "master"
    machine_type = "f1-micro"

    boot_disk {
        initialize_params {
            image = "debian-cloud/debian-9"
        }
    }

    network_interface {
        # default network is created for all GCP projects
        network = "default"
        access_config {
          
        }
    }

    connection {
        host = self.ipv4_address
    }

    provisioner "remote-exec" {
        inline = ["mkdir \"${var.server_upload_dir}\""]
    }

    provisioner "file" {
        source      = "${path.module}/files/10-kubeadm.conf"
        destination = "${var.server_upload_dir}/10-kubeadm.conf"
    }

    provisioner "remote_exec" {
        inline = [
            "vi ${var.server_upload_dir}/10-kubeadm.conf -c \"set ff=unix | wq\""
        ]
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

    provisioner "remote_exec" {
        inline = [
            "vi ${var.server_upload_dir}/bootstrap.sh -c \"set ff=unix | wq\""
        ]
    }

    provisioner "file" {
        content = templatefile("${path.module}/templates/master.sh", {
            feature_gates    = var.feature_gates,
            pod_network_cidr = var.pod_network_cidr,
        })
        destination = "${var.server_upload_dir}/master.sh"
    }

    provisioner "remote_exec" {
        inline = [
            "vi ${var.server_upload_dir}/master.sh -c \"set ff=unix | wq\""
        ]
    }

    provisioner "remote-exec" {
        inline = [
            "set -xve",
            "chmod +x \"${var.server_upload_dir}/bootstrap.sh\" \"${var.server_upload_dir}/master.sh\"",
            "\"${var.server_upload_dir}/bootstrap.sh\"",
            "\"${var.server_upload_dir}/master.sh\"",
        ]
    }

    provisioner "local-exec" {
        command = "bash ${path.module}/scripts/copy-k8s-secrets.sh"

        environment = {
            K8S_CONFIG   = local.k8s_config
            KUBEADM_JOIN = local.kubeadm_join
            SSH_HOST     = hcloud_server.master.ipv4_address
        }
    }
}

resource "google_compute_instance" "node" {
    count = var.node_count
    name = "worker-${count.index + 1}"
    machine_type = "f1-micro"

    boot_disk {
        initialize_params {
            image = "debian-cloud/debian-9"
        }
    }

    network_interface {
        # default network is created for all GCP projects
        network = "default"
        access_config {
          
        }
    }

    connection {
        host = self.ipv4_address
    }

    provisioner "remote-exec" {
        inline = ["mkdir \"${var.server_upload_dir}\""]
    }

    provisioner "file" {
        source      = "${path.module}/files/10-kubeadm.conf"
        destination = "${var.server_upload_dir}/10-kubeadm.conf"
    }

    provisioner "remote-exec" {
        inline = [
            "vim ${var.server_upload_dir}/10-kubeadm.conf -c \"set ff=unix | wq\""
        ]
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
        inline = [
            "vim ${var.server_upload_dir}/bootstrap.sh -c \"set ff=unix | wq\""
        ]
    }

    provisioner "file" {
        source      = local.kubeadm_join
        destination = "${var.server_upload_dir}/kubeadm_join"
    }

    provisioner "remote-exec" {
        inline = [
            "vim ${var.server_upload_dir}/kubeadm_join -c \"set ff=unix | wq\""
        ]
    }

    provisioner "remote-exec" {
        inline = [
            "set -xve",
            "chmod +x \"${var.server_upload_dir}/bootstrap.sh\"",
            "\"${var.server_upload_dir}/bootstrap.sh\"",
            "eval $(cat ${var.server_upload_dir}/kubeadm_join) && systemctl enable docker kubelet",
        ]
    }

    depends_on = [google_compute_instance.master]
}

locals {
    k8s_config   = "${path.module}/secrets/admin.conf"
    kubeadm_join = "${path.module}/secrets/kubeadm_join"
}

provider "kubernetes" {
    config_path = local.k8s_config
    host        = "https://${google_compute_instance.master.ipv4_address}"
}

#resource "google_ssh_key" "admin_ssh_keys" {
#  for_each   = var.admin_ssh_keys
#  name       = each.key
#  public_key = lookup(each.value, "key_file", "__missing__") == "__missing__" ? lookup(each.value, "key_data") : file(lookup(each.value, "key_file"))
#}

/*
resource "hcloud_server" "node" {
  count       = var.node_count
  name        = "node-${count.index + 1}"
  server_type = var.node_type
  image       = var.node_image
  depends_on  = [hcloud_server.master]
  ssh_keys    = [for key in hcloud_ssh_key.admin_ssh_keys : key.id]
  location    = var.hetzner_location

  // FIXME: re-create node on change in the scripts content; triggers do not work here

  connection {
    host = self.ipv4_address
  }

  provisioner "remote-exec" {
    inline = ["mkdir \"${var.server_upload_dir}\""]
  }

  provisioner "file" {
    source      = "${path.module}/files/10-kubeadm.conf"
    destination = "${var.server_upload_dir}/10-kubeadm.conf"
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

  provisioner "file" {
    source      = local.kubeadm_join
    destination = "${var.server_upload_dir}/kubeadm_join"
  }

  provisioner "remote-exec" {
    inline = [
      "set -xve",
      "chmod +x \"${var.server_upload_dir}/bootstrap.sh\"",
      "\"${var.server_upload_dir}/bootstrap.sh\"",
      "eval $(cat ${var.server_upload_dir}/kubeadm_join) && systemctl enable docker kubelet",
    ]
  }

}

resource "null_resource" "cluster_firewall_master" {
  triggers = {
    deploy_script = templatefile("${path.module}/templates/generate-firewall.sh", {
      k8s_master_ipv4 = hcloud_server.master.ipv4_address,
      k8s_nodes_ipv4  = join(" ", [for node in hcloud_server.node : node.ipv4_address]),
      master          = "true",
    }),
    k8s_master_ipv4   = hcloud_server.master.ipv4_address,
    server_upload_dir = var.server_upload_dir
  }

  connection {
    host = self.triggers.k8s_master_ipv4
  }

  provisioner "file" {
    content     = self.triggers.deploy_script
    destination = "${self.triggers.server_upload_dir}/generate-firewall.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "set -xve",
      "chmod +x \"${self.triggers.server_upload_dir}/generate-firewall.sh\"",
      "\"${self.triggers.server_upload_dir}/generate-firewall.sh\"",
    ]
  }

}

# NOTE: null_resource.cluster_firewall is never destroyed (even if terraform does it it stays in effect on infra)
# FIXME: use map instead of setunion in for_each to allow nice naming of firewall resources
resource "null_resource" "cluster_firewall_node" {
  count = var.node_count
  triggers = {
    deploy_script = templatefile("${path.module}/templates/generate-firewall.sh", {
      k8s_master_ipv4 = hcloud_server.master.ipv4_address,
      k8s_nodes_ipv4  = join(" ", [for node in hcloud_server.node : node.ipv4_address]),
      master          = "false",
    }),
    k8s_node_ipv4     = hcloud_server.node[count.index].ipv4_address
    server_upload_dir = var.server_upload_dir
  }

  connection {
    host = self.triggers.k8s_node_ipv4
  }

  provisioner "file" {
    content     = self.triggers.deploy_script
    destination = "${self.triggers.server_upload_dir}/generate-firewall.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "set -xve",
      "chmod +x \"${self.triggers.server_upload_dir}/generate-firewall.sh\"",
      "\"${self.triggers.server_upload_dir}/generate-firewall.sh\"",
    ]
  }

}

*/