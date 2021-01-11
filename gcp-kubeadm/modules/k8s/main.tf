provider "google" {
    project = var.gcp_project
    region = "us-central1"
    zone = "us-central1-c"
}

provider "kubernetes" {
    config_path = local.k8s_config
    host        = "https://${google_compute_instance.master.ipv4_address}"
}

locals {
    k8s_config   = "${path.module}/secrets/admin.conf"
    kubeadm_join = "${path.module}/secrets/kubeadm_join"
}

data "google_client_openid_userinfo" "me" {
}

resource "google_compute_project_metadata" "my_ssh_key" {
    metadata = {
      ssh-keys = <<EOF
      ubuntu-user:ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAzYjBY10oK9lG4H8+sWMxe5eFXMe/fxNQEbkFiAHzmIo0dE0UAtlMb6W9t68m4CSjQaVyPFeLhA4qZRgyUxPtB3tXhwaRkBqcxrDNmuzPa0rJ11HNCnUPKk3+OwiAT5rF3AxHBW0vdHpeLtw2gJsK6VMA31wP4l7spBCMcmJGUMsdILJwBGh7b9MpZl9IIDpMaDXVcXi4Ho+kl9D/5T9fxE3zHgj0Y6JzgVCN0yH3XHjnfvU3+vHdlQ8Lkg4rY/nh5jkwB5JFVrXkmMr568K1UwbaVcBUf2Wao1EeJzqNvqJQ/y5ec2UKa/D3v52MJ7N2eyLmb3tjSnzFwvCiV/eF5Q== ubuntu-user
EOF
    }
    project = var.gcp_project
}

resource "google_compute_instance" "master"{
    name = "master"
    machine_type = "f1-micro"
    metadata = {
        block-project-ssh-keys = false
    }

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
        host = self.network_interface.0.access_config.0.nat_ip
        type = "ssh"
        user = "ubuntu-user"
        private_key = file("C:/Users/pcp071098/Documents/mayastor-terraform-gcp.pem")
    }

    provisioner "remote-exec" {
      inline = ["echo LOCAL EXEC PROVISIONER OPERATIONAL"]
    }

    depends_on = [google_compute_project_metadata.my_ssh_key]
}

resource "google_compute_instance" "node" {
    count = var.node_count
    name = "worker-${count.index + 1}"
    machine_type = "f1-micro"

    metadata = {
        block-project-ssh-keys = false
    }

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

    depends_on = [google_compute_instance.master, google_compute_project_metadata.my_ssh_key]
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