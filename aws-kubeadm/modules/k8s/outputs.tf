output tags {
  value = local.tags
}        
output flannel_cidr {
  value = local.flannel_cidr
}

output proto_idx_to_prefix_list {
  value = local.proto_idx_to_prefix_list
}
output worker_instances_spec_reordered {
  value = local.worker_instances_spec_reordered
}
output idx_to_prefix_list {
  value = local.idx_to_prefix_list
}
output idx_to_worker_type_list {
  value = local.idx_to_worker_type_list
}
output idx_to_is_mayastor_worker_list {
  value = local.idx_to_is_mayastor_worker_list
} 
output prefix_to_count {
  value = local.prefix_to_count
}
output has_uuid_prefix  {
  value = local.has_uuid_prefix
}
output idx_to_node_name {
  value = local.idx_to_node_name
}

output "mayastor_worker_node_names" {
  value = flatten([for idx in range(0,length(local.idx_to_prefix_list)): local.idx_to_is_mayastor_worker_list[idx] == "true" ? [local.idx_to_node_name[idx]] : [] ])
}

output "kubeconfig" {
  value       = local.kubeconfig_file
  description = "Location of the kubeconfig file for the created cluster on the local machine."
}

output "mayastor_worker_nodes" {
  value = flatten([
      for node in aws_instance.workers : 
        node.tags["mayastor-worker"] ==  "true" ? 
        [{
          name       = node.tags["terraform-kubeadm:node"]
          subnet_id  = node.subnet_id
          private_ip = node.private_ip
          public_ip  = node.tags["terraform-kubeadm:node"] == "master" ? aws_eip.master.public_ip : node.public_ip
          type       = node.tags["type"]
        }] : []
  ])
  description = "Name, public and private IP address, and subnet ID of all the mayastor worker nodes of the created cluster. Master is at index 0. All items are maps with name, subnet_id, private_ip, public_ip keys."
}

output "cluster_nodes" {
  value = [
    for i in concat([aws_instance.master], aws_instance.workers, ) : {
      name       = i.tags["terraform-kubeadm:node"]
      subnet_id  = i.subnet_id
      private_ip = i.private_ip
      public_ip  = i.tags["terraform-kubeadm:node"] == "master" ? aws_eip.master.public_ip : i.public_ip
    }
  ]
  description = "Name, public and private IP address, and subnet ID of all nodes of the created cluster. Master is at index 0. All items are maps with name, subnet_id, private_ip, public_ip keys."
}

output "vpc_id" {
  value       = aws_security_group.egress.vpc_id
  description = "ID of the VPC in which the cluster has been created."
}

#output "mayastor_disk" {
#  value = lookup(var.aws_worker_instances, var.aws_instance_type_worker)
#}

