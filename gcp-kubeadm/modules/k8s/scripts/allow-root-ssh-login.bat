rem hacky approach for adding the public key to PuTTY's local registry
rem delay for 1 minute to allow the project-wide public keys to be added to the machine
ping -n 60 127.0.0.1 >nul
echo y | pscp -P 22 %HELPER_COMMANDS_DIRECTORY_PATH%\dummy.txt ubuntu-user@%INSTANCE_IPV4_ADDRESS%:/home/ubuntu-user/ 

rem allow root SSH login
putty ubuntu-user@%INSTANCE_IPV4_ADDRESS% -m %HELPER_COMMANDS_FILE_PATH%