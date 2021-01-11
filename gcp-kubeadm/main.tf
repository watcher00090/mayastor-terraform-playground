module "k8s" {
    source = "./modules/k8s"

    node_count = var.node_count
    server_upload_dir = var.server_upload_dir
    
    install_packages = var.install_packages
    hugepages_2M_amount = var.hugepages_2M_amount

    gcp_project = var.gcp_project

    ssh_public_key_name_for_instances = var.admin_ssh_keys
}

/*
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

*/