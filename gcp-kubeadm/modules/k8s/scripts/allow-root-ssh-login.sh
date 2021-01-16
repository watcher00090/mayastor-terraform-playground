ssh -n -i $PRIVATE_KEY_ABSOLUTE_PATH -o UserKnownHostsFile=~/.ssh/known_hosts -o StrictHostKeyChecking=no -t ubuntu-user@$INSTANCE_IPV4_ADDRESS "sudo sed -i 's/PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config"
ssh -n -i $PRIVATE_KEY_ABSOLUTE_PATH -o UserKnownHostsFile=~/.ssh/known_hosts -o StrictHostKeyChecking=no -t ubuntu-user@$INSTANCE_IPV4_ADDRESS "sudo systemctl restart ssh"
