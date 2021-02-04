module "k8s" {
  source = "./modules/k8s"

  cluster_name = var.cluster_name
  num_workers  = !var.use_worker_instances_spec ? var.num_workers : sum([for item in var.worker_instances_spec : parseint(lookup(item, "count", var.worker_instances_spec_default_num_workers_per_type),10)])
  use_worker_instances_spec = var.use_worker_instances_spec
  worker_instances_spec = var.worker_instances_spec
  worker_instances_spec_default_num_workers_per_type = var.worker_instances_spec_default_num_workers_per_type

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
}

module "mayastor-dependencies" {
  source = "./modules/mayastor-dependencies"

  docker_insecure_registry = var.docker_insecure_registry
  k8s_master_ip            = module.k8s.cluster_nodes[0].public_ip

  workers = {
    for worker in module.k8s.mayastor_worker_nodes :
      worker.name => worker.public_ip
  }
  depends_on = [module.k8s]
}

module "mayastor" {
  count      = var.deploy_mayastor ? 1 : 0
  depends_on = [module.mayastor-dependencies, module.k8s]

  k8s_master_ip               = module.k8s.cluster_nodes[0].public_ip
  mayastor_disk               = module.k8s.mayastor_disk
  mayastor_replicas           = var.mayastor_replicas
  mayastor_use_develop_images = var.mayastor_use_develop_images
  node_names                  = [for worker in module.k8s.mayastor_worker_nodes : worker.name]
  server_upload_dir           = "/root/tf-upload"
  source                      = "./modules/mayastor"
}
