#output "master_ip" {
#  value = module.k8s.master_ip
#}

#output "node_ips" {
#  value = [for worker in slice(module.k8s.cluster_nodes, 1, length(module.k8s.cluster_nodes)) : worker.public_ip]
#}

#output "k8s_admin_conf" {
#  value = abspath(module.k8s.k8s_admin_conf)
#}

#output "kubeconfig" {
#  value = abspath(module.k8s.k8s_admin_conf)
#}

output "kubeconfig" {
  value       = module.k8s.k8s_admin_conf
  description = "Location of the kubeconfig file for the created cluster on the local machine."
}

output "cluster_nodes" {
  value       = module.k8s.cluster_nodes
  description = "Name, public and private IP address, and subnet ID of the nodes of the created cluster."
}