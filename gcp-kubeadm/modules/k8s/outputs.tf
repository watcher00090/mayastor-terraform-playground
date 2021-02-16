output "kubeconfig" {
  value = local.kubeconfig_file
  description = "Location of the kubeconfig file for the created cluster on the local machine."
}

output "cluster_nodes" {
  value = [
    for n in concat([google_compute_instance.master], google_compute_instance.node) : {
      name       = n.name,
      public_ip  = n.network_interface.0.access_config.0.nat_ip,
      private_ip = n.network_interface.0.network_ip,
    }
  ]
}