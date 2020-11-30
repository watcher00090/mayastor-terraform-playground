output "admin_ssh_keys" {
  value = merge(jsondecode(http.mayadata_ssh_keys.body), var.admin_ssh_keys)
}
