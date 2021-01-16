rem ! /bin/bash

rem set -eu

.\get-kubeadm-dir-name.bat %KUBEADM_JOIN%
set /p KUBEADM_DIR_NAME=<bash-dump.txt

echo "Creating a directory called %KUBEADM_DIR_NAME% to store joining and configuration info of the cluster...."
mkdir %KUBEADM_DIR_NAME%

# get join command
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i %PRIVATE_KEY_ABSOLUTE_PATH% root@%SSH_HOST% "kubeadm token create --print-join-command > ~/kubeadm_join_dump.txt" 
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i %PRIVATE_KEY_ABSOLUTE_PATH% root@%SSH_HOST%:~/kubeadm_join_dump.txt %KUBEADM_JOIN%

# get admin.conf
# admin_conf_dump.txt
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i %PRIVATE_KEY_ABSOLUTE_PATH% root@%SSH_HOST%:/etc/kubernetes/admin.conf %K8S_CONFIG%
