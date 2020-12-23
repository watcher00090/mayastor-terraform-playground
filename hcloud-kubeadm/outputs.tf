output "master_ip" {
  value = module.k8s.master_ip
}

output "node_ips" {
  value = [for worker in slice(module.k8s.cluster_nodes, 1, length(module.k8s.cluster_nodes)) : worker.public_ip]
}

output "k8s_admin_conf" {
  value = abspath(module.k8s.k8s_admin_conf)
}

output "kubeconfig" {
  value = abspath(module.k8s.k8s_admin_conf)
}
