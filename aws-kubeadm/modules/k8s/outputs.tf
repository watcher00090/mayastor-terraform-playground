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

output "mayastor_disk" {
  value = lookup(var.aws_worker_instances, var.aws_instance_type_worker)
}

