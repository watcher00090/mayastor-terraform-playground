resource "null_resource" "short_delay" {
    provisioner "local-exec" {
        command = <<EOF
            sleep 240
        EOF
    }
}