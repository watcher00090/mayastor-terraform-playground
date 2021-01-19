
call %WINDOWS_MODULE_PATH%\scripts\copy-k8s-secrets-helper.bat %KUBEADM_JOIN%
set /p KUBEADM_DIR_NAME=<bash-dump.txt

echo "Creating a directory called %KUBEADM_DIR_NAME% to store joining and configuration info of the cluster...."
mkdir %KUBEADM_DIR_NAME%

rem prepare to fetch join command
putty root@%SSH_HOST% -m %HELPER_COMMANDS_FILE_PATH%

rem get join command
pscp -P 22 root@%SSH_HOST%:/root/kubeadm_join_dump.txt %KUBEADM_JOIN%

rem get admin.conf
pscp -P 22 root@%SSH_HOST%:/etc/kubernetes/admin.conf %K8S_CONFIG%