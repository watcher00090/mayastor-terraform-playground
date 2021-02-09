module "k8s" {
  source = "./modules/k8s"

  node_count        = var.node_count
  server_upload_dir = var.server_upload_dir

  install_packages    = var.install_packages
  hugepages_2M_amount = var.hugepages_2M_amount

  gcp_project = var.gcp_project

  admin_ssh_keys = var.admin_ssh_keys

  host_type = var.host_type
}


module "mayastor-dependencies" {
  source = "./modules/mayastor-dependencies"

  docker_insecure_registry = var.docker_insecure_registry

  k8s_master_ip = module.k8s.master_node.public_ip

  workers = {
    for worker in slice(module.k8s.cluster_nodes, 1, length(module.k8s.cluster_nodes)) :
    worker.name => worker.public_ip
  }

  #nodes = {
  #  for node in module.k8s.cluster_nodes :
  #  node.name => node.public_ip
  #}

  #master = {
  #  (module.k8s.master_node.name) = (module.k8s.master_node.public_ip)
  #}

  depends_on = [module.k8s]
}

module "short-delay" {
  source = "./modules/short-delay"

  host_type = var.host_type

  depends_on = [module.mayastor-dependencies]
}

module "mayastor" {
  source = "./modules/mayastor"

  #host_type                   = var.host_type
  count                       = var.deploy_mayastor ? 1 : 0
  depends_on                  = [module.mayastor-dependencies, module.short-delay]
  k8s_master_ip               = module.k8s.master_ip
  mayastor_disk               = "/dev/sdb"
  mayastor_replicas           = var.mayastor_replicas
  mayastor_use_develop_images = var.mayastor_use_develop_images
  node_names                  = [for worker in slice(module.k8s.cluster_nodes, 1, length(module.k8s.cluster_nodes)) : worker.name]
  server_upload_dir           = var.server_upload_dir
}






/*


module "mayastor-dependencies" {
  source = "./modules/mayastor-dependencies"

  docker_insecure_registry = var.docker_insecure_registry
  k8s_master_ip            = module.k8s.master_ip

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


*/