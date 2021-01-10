output "master_ip" {
  value = google_compute_instance.master.ipv4_address
}

output "cluster_nodes" {
  value = [
    for n in concat([google_compute_instance.master], google_compute_instance.node) : {
      name      = n.name,
      public_ip = n.ipv4_address,
    }
  ]
}

#output "k8s_admin_conf" {
#  value = "${path.module}/secrets/admin.conf"
#}
