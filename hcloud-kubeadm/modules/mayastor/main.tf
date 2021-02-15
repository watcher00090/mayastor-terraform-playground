/*
resource "null_resource" "debug" {
  provisioner "local-exec" {
    command = <<EOF
        echo ================================== >> ~/.mayastor_var_dump
        echo ${var.k8s_master_ip} >> ~/.mayastor_var_dump
        echo 'var.mayastor_replicas=${var.mayastor_replicas}' >> ~/.mayastor_var_dump
        echo 'var.num_mayastor_workers}=${var.num_mayastor_workers}' >> ~/.mayastor_var_dump    
        echo 'var.mayastor_use_develop_images=${var.mayastor_use_develop_images}' >> ~/.mayastor_var_dump
        echo 'var.node_names=${var.node_names}' >> ~/.mayastor_var_dump
        echo 'var.idx_to_mount_point=${var.idx_to_mount_point}' >> ~/.mayastor_var_dump
        echo 'var.cluster_name=${var.cluster_name}' >> ~/.mayastor_var_dump
        echo 'var.server_upload_dir=${var.server_upload_dir}' >> ~/.mayastor_var_dump
    EOF
  }
}
*/

# variable validators cannot reference other variables, let's validate relation
# between mayastor_replicas and number of cluster nodes here
resource "null_resource" "validate_replica_count" {
  provisioner "local-exec" {
    command = <<-EOF
    set -e
    if [ "${var.mayastor_replicas}" -gt "${var.num_mayastor_workers}" ]; then
      echo "Variable mayastor_replicas cannot be greater than number of cluster nodes"
      exit 1
    fi
    EOF
  }
}

resource "null_resource" "server_upload_dir" {
  triggers = {
    k8s_master_ip     = var.k8s_master_ip
    server_upload_dir = var.server_upload_dir
  }
  connection {
    host = self.triggers.k8s_master_ip
  }
  provisioner "remote-exec" {
    inline = [
      "set -exv",
      "mkdir -p \"${self.triggers.server_upload_dir}\""
    ]
  }
}

// FIXME it would be nice to have yamls in HCL; but rather to have them in mayadata repo as snippets or TF module
resource "null_resource" "mayastor" {
  triggers = {
    k8s_master_ip      = var.k8s_master_ip
    mayastor_image_tag = var.mayastor_use_develop_images ? "develop" : "master"
  }
  connection {
    host = self.triggers.k8s_master_ip
  }
  provisioner "remote-exec" {
    inline = [
      "set -exv",
      "kubectl create ns mayastor",
      #"kubectl create -f https://raw.githubusercontent.com/openebs/Mayastor/${self.triggers.mayastor_image_tag}/deploy/namespace.yaml",
      "kubectl create -f https://raw.githubusercontent.com/openebs/Mayastor/${self.triggers.mayastor_image_tag}/deploy/moac-rbac.yaml",
      "kubectl apply -f https://raw.githubusercontent.com/openebs/Mayastor/${self.triggers.mayastor_image_tag}/csi/moac/crds/mayastorpool.yaml",
      "kubectl apply -f https://raw.githubusercontent.com/openebs/Mayastor/${self.triggers.mayastor_image_tag}/deploy/nats-deployment.yaml",
      "kubectl apply -f https://raw.githubusercontent.com/openebs/Mayastor/${self.triggers.mayastor_image_tag}/deploy/csi-daemonset.yaml",
      "kubectl apply -f https://raw.githubusercontent.com/openebs/Mayastor/${self.triggers.mayastor_image_tag}/deploy/moac-deployment.yaml",
      "kubectl apply -f https://raw.githubusercontent.com/openebs/Mayastor/${self.triggers.mayastor_image_tag}/deploy/mayastor-daemonset.yaml",
      "sleep 10",
    ]
  }
  provisioner "remote-exec" {
    when = destroy
    inline = [
      "set -exv",
      "kubectl delete -f https://raw.githubusercontent.com/openebs/Mayastor/${self.triggers.mayastor_image_tag}/deploy/mayastor-daemonset.yaml",
      "kubectl delete -f https://raw.githubusercontent.com/openebs/Mayastor/${self.triggers.mayastor_image_tag}/deploy/moac-deployment.yaml",
      "kubectl delete -f https://raw.githubusercontent.com/openebs/Mayastor/${self.triggers.mayastor_image_tag}/deploy/csi-daemonset.yaml",
      "kubectl delete -f https://raw.githubusercontent.com/openebs/Mayastor/${self.triggers.mayastor_image_tag}/deploy/nats-deployment.yaml",
      "kubectl delete -f https://raw.githubusercontent.com/openebs/Mayastor/${self.triggers.mayastor_image_tag}/csi/moac/crds/mayastorpool.yaml",
      "kubectl delete -f https://raw.githubusercontent.com/openebs/Mayastor/${self.triggers.mayastor_image_tag}/deploy/moac-rbac.yaml",
      "kubectl delete -f https://raw.githubusercontent.com/openebs/Mayastor/${self.triggers.mayastor_image_tag}/deploy/namespace.yaml",
    ]
  }
}

resource "null_resource" "mayastor_use_develop_images" {
  count      = var.mayastor_use_develop_images ? 1 : 0
  depends_on = [null_resource.mayastor]
  triggers = {
    k8s_master_ip = var.k8s_master_ip
  }
  connection {
    host = self.triggers.k8s_master_ip
  }
  provisioner "remote-exec" {
    inline = [
      "set -xve",
      "kubectl -n mayastor patch daemonsets.apps mayastor --patch '{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"mayastor\",\"image\":\"mayadata/mayastor:develop\"}]}}}}'",
      "kubectl -n mayastor patch daemonsets.apps mayastor-csi --patch '{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"mayastor-csi\",\"image\":\"mayadata/mayastor-csi:develop\"}]}}}}'",
      "kubectl -n mayastor patch deployment.apps moac --patch '{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"moac\",\"image\":\"mayadata/moac:develop\"}]}}}}'",
    ]
  }
  provisioner "remote-exec" {
    when = destroy
    inline = [
      "set -xve",
      "kubectl -n mayastor patch daemonsets.apps mayastor --patch '{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"mayastor\",\"image\":\"mayadata/mayastor:latest\"}]}}}}'",
      "kubectl -n mayastor patch daemonsets.apps mayastor-csi --patch '{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"mayastor-csi\",\"image\":\"mayadata/mayastor-csi:latest\"}]}}}}'",
      "kubectl -n mayastor patch deployment.apps moac --patch '{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"moac\",\"image\":\"mayadata/moac:latest\"}]}}}}'",
    ]
  }
}

resource "null_resource" "mayastor-pool-local" {
  depends_on = [null_resource.mayastor]
  count = var.num_mayastor_workers

  triggers = {
    k8s_master_ip = var.k8s_master_ip
    mayastor_pool_local_yaml = templatefile("${path.module}/templates/mayastor-pool-local.yaml", {
      mayastor_disk = "/dev/nvme1n1", #var.idx_to_mount_point[count.index],
      node          = var.node_names[count.index],
    }),
    server_upload_dir = var.server_upload_dir
    node_names = jsonencode(var.node_names)
  }
  connection {
    host = self.triggers.k8s_master_ip
  }
  provisioner "file" {
    content     = self.triggers.mayastor_pool_local_yaml
    destination = "${self.triggers.server_upload_dir}/mayastor_pool_local-${jsondecode(self.triggers.node_names)[count.index]}.yaml"
  }
  provisioner "remote-exec" {
    inline = ["kubectl apply -f \"${self.triggers.server_upload_dir}/mayastor_pool_local-${jsondecode(self.triggers.node_names)[count.index]}.yaml\""]
  }
  provisioner "remote-exec" {
    when   = destroy
    inline = ["kubectl delete -f \"${self.triggers.server_upload_dir}/mayastor_pool_local-${jsondecode(self.triggers.node_names)[count.index]}.yaml\""]
  }
}

resource "null_resource" "mayastor-storageclass-nvme" {
  depends_on = [null_resource.mayastor-pool-local, null_resource.validate_replica_count]
  triggers = {
    k8s_master_ip = var.k8s_master_ip
    mayastor_storageclass_local_yaml = templatefile("${path.module}/templates/mayastor-storageclass-nvme.yaml", {
      replicas = var.mayastor_replicas == -1 ? length(var.node_names) : var.mayastor_replicas,
    }),
    server_upload_dir = var.server_upload_dir
  }
  connection {
    host = self.triggers.k8s_master_ip
  }
  provisioner "file" {
    content     = self.triggers.mayastor_storageclass_local_yaml
    destination = "${self.triggers.server_upload_dir}/mayastor_storageclass_nvme.yaml"
  }
  provisioner "remote-exec" {
    inline = ["kubectl apply -f \"${self.triggers.server_upload_dir}/mayastor_storageclass_nvme.yaml\""]
  }
  provisioner "remote-exec" {
    when   = destroy
    inline = ["kubectl delete -f \"${self.triggers.server_upload_dir}/mayastor_storageclass_nvme.yaml\""]
  }
}

