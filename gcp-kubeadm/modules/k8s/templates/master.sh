#!/bin/bash
set -eu

# Open port 6443 - the rest is the same as in bootstrap.sh
sudo cat > /etc/iptables/rules.v4 << EOF
*mangle
:PREROUTING ACCEPT
-F PREROUTING
-A PREROUTING -i eth0 -m tcp -p tcp --dport 22 -j ACCEPT
-A PREROUTING -i eth0 -m tcp -p tcp --dport 6443 -j ACCEPT
-A PREROUTING -i eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
-A PREROUTING -i eth0 -j DROP
COMMIT
EOF
sudo systemctl restart local-iptables.service

# Initialize Cluster 
if [ -n "${feature_gates}" ]; then
	sudo kubeadm init --pod-network-cidr="${pod_network_cidr}" --feature-gates "${feature_gates}" --apiserver-cert-extra-sans=${master_private_ipv4_address},${master_public_ipv4_address}
#	sudo kubeadm init --pod-network-cidr="${pod_network_cidr}" --feature-gates "${feature_gates}" --apiserver-cert-extra-sans=${master_public_ipv4_address}
else
	sudo kubeadm init --pod-network-cidr="${pod_network_cidr}" --apiserver-cert-extra-sans=${master_private_ipv4_address},${master_public_ipv4_address}
#	sudo kubeadm init --pod-network-cidr="${pod_network_cidr}" --feature-gates "${feature_gates}" --apiserver-cert-extra-sans=${master_public_ipv4_address}
fi

sudo systemctl enable docker kubelet

#echo s/${master_private_ipv4_address}/${master_public_ipv4_address}/g > ~/test.file
#sudo sed -i "s/${master_private_ipv4_address}/${master_public_ipv4_address}/g" /etc/kubernetes/admin.conf

# Prepare kubeconfig file for download to local machine
mkdir -p /home/ubuntu/.kube
cp /etc/kubernetes/admin.conf /home/ubuntu
cp /etc/kubernetes/admin.conf /home/ubuntu/.kube/config # enable kubectl on the node
sudo mkdir /root/.kube
sudo cp /etc/kubernetes/admin.conf /root/.kube/config
chown ubuntu:ubuntu /home/ubuntu/admin.conf /home/ubuntu/.kube/config

# Set API server address of cluster
kubectl --kubeconfig /home/ubuntu/admin.conf config set-cluster kubernetes --server https://${master_public_ipv4_address}:6443

# Indicate completion of bootstrapping on this node
touch /home/ubuntu/done

#echo ${master_public_ipv4_address} > ~/server_address.txt
