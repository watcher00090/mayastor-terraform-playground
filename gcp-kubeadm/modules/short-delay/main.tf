locals {
  windows_module_path = replace(path.module, "///", "\\")
  on_windows_host     = upper(var.host_type) == "WINDOWS" ? true : false
}

resource "null_resource" "short_delay" {
    provisioner "local-exec" {
        command = local.on_windows_host ? "ping -n 180 127.0.0.1 >nul" : "sleep(180)"
    }
}