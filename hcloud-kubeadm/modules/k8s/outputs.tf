output "master_ip" {
  value = hcloud_server.master.ipv4_address
}

output "cluster_nodes" {
  value = [
    for n in concat([hcloud_server.master], hcloud_server.node) : {
      name      = n.name,
      public_ip = n.ipv4_address,
    }
  ]
}

output "k8s_admin_conf" {
  value = "${path.module}/secrets/admin.conf"
}
