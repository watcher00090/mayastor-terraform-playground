resource "null_resource" "flannel" {
  triggers = {
    flannel_yaml = templatefile(local.on_windows_host ? "${local.windows_module_path}\\files\\kube-flannel-wireguard.yaml" : "${path.module}/files/kube-flannel-wireguard.yaml", {
      pod_network_cidr = var.pod_network_cidr,
    }),
    gcp_master        = google_compute_instance.master.network_interface.0.access_config.0.nat_ip
    server_upload_dir = var.server_upload_dir
  }
  connection {
    host  = self.triggers.gcp_master
    type  = "ssh"
    agent = "true"
  }

  provisioner "file" {
    content     = self.triggers.flannel_yaml
    destination = "${self.triggers.server_upload_dir}/kube-flannel-wireguard.yaml"
  }

  provisioner "remote-exec" {
    inline = ["set -xve", "vi ${self.triggers.server_upload_dir}/kube-flannel-wireguard.yaml -c \" set ff=unix | wq\""]
  }

  provisioner "remote-exec" {
    inline = ["kubectl apply -f ${self.triggers.server_upload_dir}/kube-flannel-wireguard.yaml"]
  }

  provisioner "remote-exec" {
    when   = destroy
    inline = ["kubectl delete -f ${self.triggers.server_upload_dir}/kube-flannel-wireguard.yaml"]
  }
}

