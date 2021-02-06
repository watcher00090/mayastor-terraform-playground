module "utils" {
  source = "./modules/utils"
  worker_instances_spec = var.worker_instances_spec
  use_worker_instances_spec = var.use_worker_instances_spec
  use_old_style_worker_names = var.use_old_style_worker_names
  worker_instances_spec_default_num_workers_per_type = var.worker_instances_spec_default_num_workers_per_type
  num_chars_for_group_identifier = var.num_chars_for_group_identifier
  num_workers = var.num_workers
}

module "k8s" {
  source = "./modules/k8s"

  cluster_name = var.cluster_name
  
  use_worker_instances_spec = var.use_worker_instances_spec

  #num_mayastor_workers = module.utils.num_mayastor_workers
  aws_worker_instances = var.aws_worker_instances
  num_workers  = module.utils.num_workers
  worker_instances_spec = module.utils.worker_instances_spec

  worker_instances_spec_default_num_workers_per_type = var.worker_instances_spec_default_num_workers_per_type
  use_old_style_worker_names = var.use_old_style_worker_names

  aws_instance_root_size_gb = var.aws_instance_root_size_gb
  aws_instance_type_worker  = var.aws_instance_type_worker
  aws_region                = var.aws_region
  docker_version            = var.docker_version
  ebs_volume_size           = var.ebs_volume_size
  flannel_version           = var.flannel_version
  kubernetes_version        = var.kubernetes_version

  ssh_public_keys = var.ssh_public_keys

  tags = var.tags

  install_packages            = var.install_packages
  mayastor_use_develop_images = var.mayastor_use_develop_images

  depends_on = [module.utils]
}

module "mayastor-dependencies" {
  source = "./modules/mayastor-dependencies"

  docker_insecure_registry = var.docker_insecure_registry
  k8s_master_ip            = module.k8s.cluster_nodes[0].public_ip
  num_mayastor_workers = module.utils.num_mayastor_workers
  mayastor_worker_node_names = [for worker in module.k8s.mayastor_worker_nodes : worker.name]
  idx_to_mayastor_worker_ip = [for mayastor_worker in module.k8s.mayastor_worker_nodes: mayastor_worker["public_ip"]]

  node_names                  = [for worker in module.k8s.mayastor_worker_nodes : worker.name]
  idx_to_mount_point          = [for worker in module.k8s.mayastor_worker_nodes : var.aws_worker_instances[worker.type]]

  workers = module.k8s.mayastor_worker_nodes
  depends_on = [module.k8s, module.utils]
}

/*
module "short_delay" {
  source = "./modules/short_delay"
  depends_on = [module.mayastor-dependencies]
}
*/

module "mayastor" {
  count = var.deploy_mayastor ? 1 : 0
  #depends_on = [module.mayastor-dependencies, module.k8s, module.utils, module.short_delay]
  depends_on = [module.mayastor-dependencies, module.k8s, module.utils]

  k8s_master_ip = module.k8s.cluster_nodes[0].public_ip
  mayastor_replicas = var.mayastor_replicas
  num_mayastor_workers = module.utils.num_mayastor_workers
  mayastor_use_develop_images = var.mayastor_use_develop_images
  node_names = [for worker in module.k8s.mayastor_worker_nodes : worker.name]
  idx_to_mount_point = [for worker in module.k8s.mayastor_worker_nodes : var.aws_worker_instances[worker.type]]
  cluster_name = var.cluster_name
  server_upload_dir = "/root/tf-upload"
  source = "./modules/mayastor"
}