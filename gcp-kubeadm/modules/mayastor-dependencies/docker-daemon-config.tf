# FIXME: use configuration management tool rather than terraform ;-)
#
# Or so they say in doc. However this seem to work, install/uninstall/update
# :-) Please let me know if not.

# TODO see that this works with an insecure docker registry when run on a Windows host
resource "null_resource" "docker_daemon_config_workers" {
  # for_each = var.workers
  for_each = var.nodes

  connection {
    type  = "ssh"
    host  = jsondecode(self.triggers.workers)[each.key]
    user  = "root"
    agent = true
  }

  provisioner "file" {
    content     = self.triggers.docker_config
    destination = "/etc/docker/daemon.json"
  }

  provisioner "remote-exec" {
    inline = ["set -xve", "sudo vi /etc/docker/daemon.json -c \" set ff=unix | wq\""]
  }

  provisioner "remote-exec" {
    inline = ["systemctl restart docker"]
  }

  #provisioner "remote-exec" {
  #  when = destroy
  #  inline = [
  #    "set -e",
  #    "rm /etc/docker/daemon.json",
  #    "systemctl restart docker",
  #  ]
  #}

  triggers = {
    docker_config = <<-EOF
    {
      "insecure-registries" : ${var.docker_insecure_registry != "" ? jsonencode([var.docker_insecure_registry]) : "[]"}
    }
    EOF
    #workers       = jsonencode(var.workers)
    workers = jsonencode(var.nodes)
  }
}

