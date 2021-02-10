output "master_ip" {
  value = google_compute_instance.master.network_interface.0.access_config.0.nat_ip
}

output "master_node" {
  value = {
    name      = google_compute_instance.master.name
    public_ip = google_compute_instance.master.network_interface.0.access_config.0.nat_ip
  }
}

output "cluster_nodes" {
  value = [
    for n in concat([google_compute_instance.master], google_compute_instance.node) : {
      name      = n.name,
      public_ip = n.network_interface.0.access_config.0.nat_ip,
    }
  ]
}

output "k8s_admin_conf" {
  value = "mayastor-terraform-playground-gcp.conf"
}
