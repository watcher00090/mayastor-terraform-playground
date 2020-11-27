# These configurations should be tested

- no variables defined but `hcloud_token` and `hcloud_csi_token`
- deploy of `develop` mayastor: value of `mayastor_use_develop_images` set to `true`

# Scripts

All scripts in `./bin` should be tested. Especially `destroy-quick` tends to
get outdated quickly when adding/removing resources via terraform.
