module "k8s" {
  source = "./modules/k8s"

  admin_ssh_keys    = var.admin_ssh_keys
  hcloud_csi_token  = var.hcloud_csi_token
  hcloud_token      = var.hcloud_token
  hetzner_location  = var.hetzner_location
  node_count        = var.node_count
  server_upload_dir = var.server_upload_dir

  install_packages = var.install_packages
}

module "mayastor-dependencies" {
  source = "./modules/mayastor-dependencies"

  docker_insecure_registry = var.docker_insecure_registry

  workers = {
    for worker in slice(module.k8s.cluster_nodes, 1, length(module.k8s.cluster_nodes)) :
    worker.name => worker.public_ip
  }
  depends_on = [module.k8s]
}

module "mayastor" {
  source = "./modules/mayastor"

  count                       = var.deploy_mayastor ? 1 : 0
  depends_on                  = [module.mayastor-dependencies]
  k8s_master_ip               = module.k8s.master_ip
  mayastor_disk               = "/dev/sdb"
  mayastor_replicas           = var.mayastor_replicas
  mayastor_use_develop_images = var.mayastor_use_develop_images
  node_names                  = [for worker in slice(module.k8s.cluster_nodes, 1, length(module.k8s.cluster_nodes)) : worker.name]
  server_upload_dir           = var.server_upload_dir
}

