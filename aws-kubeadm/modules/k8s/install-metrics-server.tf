# FIXME: fix auth to kubelet and don't use --deprecated-kubelet-completely-insecure
resource "null_resource" "metrics_server" {
  depends_on = [aws_instance.master, aws_instance.workers]
  triggers = {
    k8s_master_ip          = aws_eip.master.public_ip
    metrics_server_version = var.metrics_server_version
    server_upload_dir      = var.server_upload_dir

    # FIXME: put hostnames to some variable, it's really generated in aws_instance.* machine-bootstrap.sh template
    patch_yaml = templatefile("${path.module}/templates/metrics_server_patch.yaml.tmpl", {
      "master" : "${var.cluster_name}-${aws_instance.master.tags["terraform-kubeadm:node"]}",
      "master_ip" : aws_instance.master.private_ip,
      "node_ips" : [for node in aws_instance.workers : node.private_ip],
      "nodes" : [for node in aws_instance.workers : "${var.cluster_name}-${node.tags["terraform-kubeadm:node"]}"],
    })
  }
  connection {
    host = self.triggers.k8s_master_ip
  }

  provisioner "file" {
    content     = self.triggers.patch_yaml
    destination = "${self.triggers.server_upload_dir}/metrics_server_patch.yaml"
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

