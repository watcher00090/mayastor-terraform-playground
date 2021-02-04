locals {
  worker_instances_spec = [for item in var.worker_instances_spec: ((tostring(lookup(item, "mayastor_node_label", "__missing__")) == "true") ? merge(item,{prefix="mayastor-worker"}) : (lookup(item, "prefix", "__missing__") == "__missing__" ? merge(item,{prefix="${substr(uuid(),0,var.num_chars_for_group_identifier)}"}) : item))]
  tags         = merge(var.tags, { "terraform-kubeadm:cluster" = var.cluster_name, "Name" = var.cluster_name })
  flannel_cidr = "10.244.0.0/16" # hardcoded in flannel, do not change
  proto_idx_to_prefix_list = flatten([for item in local.worker_instances_spec : item["prefix"] ])
  worker_instances_spec_reordered = flatten([for idx,item in local.worker_instances_spec: (index(local.proto_idx_to_prefix_list, item["prefix"]) != idx) ? [] : flatten([for item_prime in local.worker_instances_spec: ( item_prime["prefix"] == item["prefix"] ? [item] : []) ]) ])
  idx_to_prefix_list = flatten([for item in local.worker_instances_spec_reordered : [for idx in range(0, parseint(lookup(item, "count", var.worker_instances_spec_default_num_workers_per_type),10)) : item["prefix"] ]])
  idx_to_worker_type_list = flatten([for item in local.worker_instances_spec_reordered : ([for idx in range(0, parseint(lookup(item, "count", var.worker_instances_spec_default_num_workers_per_type),10)) : lookup(item, "type", "t3.medium")])])
  idx_to_is_mayastor_worker_list = flatten([for item in local.worker_instances_spec_reordered : ([for idx in range(0, parseint(lookup(item, "count", var.worker_instances_spec_default_num_workers_per_type),10)) : tostring(lookup(item, "mayastor_node_label", "false"))])])
  prefixes_list = toset([for item in local.worker_instances_spec_reordered : item["prefix"]])
  #prefix_to_count = {for item in local.prefixes_list}
}

module "k8s" {
  source = "./modules/k8s"

  cluster_name = var.cluster_name
  num_workers  = !var.use_worker_instances_spec ? var.num_workers : sum([for item in var.worker_instances_spec : parseint(lookup(item, "count", var.worker_instances_spec_default_num_workers_per_type),10)])
  use_worker_instances_spec = var.use_worker_instances_spec
  worker_instances_spec = [for item in var.worker_instances_spec: ((tostring(lookup(item, "mayastor_node_label", "__missing__")) == "true") ? merge(item,{prefix="mayastor-worker"}) : (lookup(item, "prefix", "__missing__") == "__missing__" ? merge(item,{prefix="${substr(uuid(),0,var.num_chars_for_group_identifier)}"}) : item))]
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
