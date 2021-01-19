rem hacky approach for adding the public key to PuTTY's local registry
echo y | pscp -P 22 ubuntu-user@%INSTANCE_IPV4_ADDRESS%:/home/ubuntu-user/dummy-file.txt .

rem allow root SSH login
putty ubuntu-user@%INSTANCE_IPV4_ADDRESS% -m %HELPER_COMMANDS_FILE_PATH%