output "master_ip" {
  value = google_compute_instance.master.network_interface.0.access_config.0.nat_ip
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
  value = local.on_windows_host ? "${local.windows_module_path}\\secrets\\admin.conf" : "{path.module}/secrets/admin.conf"
}
