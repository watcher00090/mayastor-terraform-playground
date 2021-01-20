# FIXME: fix auth to kubelet and don't use --deprecated-kubelet-completely-insecure
resource "null_resource" "metrics_server" {
  depends_on = [google_compute_instance.master, google_compute_instance.node]
  triggers = {
    k8s_master_ip          = google_compute_instance.master.network_interface.0.access_config.0.nat_ip
    metrics_server_version = var.metrics_server_version
    server_upload_dir      = var.server_upload_dir

    patch_yaml = templatefile(local.on_windows_host ? "${local.windows_module_path}\\templates\\metrics_server_patch.yaml.tmpl" : "${path.module}/templates/metrics_server_patch.yaml.tmpl", {
      "master" : google_compute_instance.master.name,
      "master_ip" : google_compute_instance.master.network_interface.0.access_config.0.nat_ip,
      "node_ips" : [for node in google_compute_instance.node : node.network_interface.0.access_config.0.nat_ip],
      "nodes" : [for node in google_compute_instance.node : node.name],
    })
  }
  connection {
    host = self.triggers.k8s_master_ip
    type = "ssh"
    agent = true
  }

  provisioner "file" {
    content     = self.triggers.patch_yaml
    destination = "${self.triggers.server_upload_dir}/metrics_server_patch.yaml"
  }

  provisioner "remote-exec" {
    inline = ["set -xve", "vi ${self.triggers.server_upload_dir}/metrics_server_patch.yaml -c \" set ff=unix | wq\""]
  }

  provisioner "remote-exec" {
    inline = ["kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v${self.triggers.metrics_server_version}/components.yaml"]
  }

  provisioner "remote-exec" {
    inline = ["kubectl -n kube-system patch deployment metrics-server --patch \"$(cat ${self.triggers.server_upload_dir}/metrics_server_patch.yaml)\""]
  }

  provisioner "remote-exec" {
    when   = destroy
    inline = ["kubectl delete -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v${self.triggers.metrics_server_version}/components.yaml"]
  }
}

