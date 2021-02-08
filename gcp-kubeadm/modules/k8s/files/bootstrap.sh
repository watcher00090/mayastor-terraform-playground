#!/bin/bash
set -eu

export DEBIAN_FRONTEND=noninteractive

apt-get install keyboard-configuration

waitforapt(){
  while fuser /var/lib/apt/lists/lock >/dev/null 2>&1 ; do
     echo "Waiting for other software managers to finish..."
     sleep 1
  done
}

# set timezone to UTC
sudo rm /etc/localtime; sudo ln -s /usr/share/zoneinfo/Etc/UTC /etc/localtime
sudo echo 'Etc/UTC' > /etc/timezone
# Is this really needed?
cat << EOF | debconf-set-selections
tzdata  tzdata/Zones/Indian     select
tzdata  tzdata/Zones/Asia       select
tzdata  tzdata/Zones/Australia  select
tzdata  tzdata/Zones/SystemV    select
tzdata  tzdata/Areas            select  Etc
tzdata  tzdata/Zones/Africa     select
tzdata  tzdata/Zones/US         select
tzdata  tzdata/Zones/Pacific    select
tzdata  tzdata/Zones/Etc        select  UTC
tzdata  tzdata/Zones/Europe     select
tzdata  tzdata/Zones/Arctic     select
tzdata  tzdata/Zones/Antarctica select
tzdata  tzdata/Zones/Atlantic   select
tzdata  tzdata/Zones/America    select
keyboard-configuration  keyboard-configuration/unsupported_layout       boolean true
keyboard-configuration  keyboard-configuration/unsupported_config_layout        boolean true
keyboard-configuration  keyboard-configuration/optionscode      string
keyboard-configuration  keyboard-configuration/variant  select  English (US)
keyboard-configuration  keyboard-configuration/switch   select  No temporary switch
keyboard-configuration  keyboard-configuration/layout   select  English (US)
keyboard-configuration  keyboard-configuration/modelcode        string  pc105
keyboard-configuration  keyboard-configuration/unsupported_config_options       boolean true
keyboard-configuration  keyboard-configuration/variantcode      string
keyboard-configuration  keyboard-configuration/layoutcode       string  us
keyboard-configuration  keyboard-configuration/altgr    select  The default for the keyboard layout
keyboard-configuration  keyboard-configuration/unsupported_options      boolean true
keyboard-configuration  keyboard-configuration/store_defaults_in_debconf_db     boolean true
keyboard-configuration  keyboard-configuration/toggle   select  No toggling
keyboard-configuration  keyboard-configuration/xkb-keymap       select  gb
keyboard-configuration  keyboard-configuration/model    select  Generic 105-key PC (intl.)
keyboard-configuration  keyboard-configuration/compose  select  No compose key
keyboard-configuration  keyboard-configuration/ctrl_alt_bksp    boolean false
EOF
sudo dpkg-reconfigure -f noninteractive tzdata
sudo dpkg-reconfigure -f noninteractive keyboard-configuration

# set fireall to use iptables-legacy (required for k8s to work - or was in the
# past)
#sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
#sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy

# disable ipv6 altogether for now
sudo echo 'net.ipv6.conf.all.disable_ipv6 = 1' > /etc/sysctl.d/01-disable-ipv6.conf
sudo sysctl 'net.ipv6.conf.all.disable_ipv6=1'

# basic firewall, proper one is set using modules.k8s.null_resource.cluster_firewall
# NOTE: on master.sh firewall is replaced by one with port 6443 open
sudo mkdir /etc/iptables
sudo cat > /etc/iptables/rules.v4 << EOF
*mangle
:PREROUTING ACCEPT
-F PREROUTING
-A PREROUTING -i eth0 -m tcp -p tcp --dport 22 -j ACCEPT
-A PREROUTING -i eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
-A PREROUTING -i eth0 -j DROP
COMMIT
EOF

sudo cat > /etc/systemd/system/local-iptables.service << EOF
[Unit]
Description=Local firewall
DefaultDependencies=no
Wants=network-pre.target systemd-modules-load.service local-fs.target
Before=network-pre.target shutdown.target
After=systemd-modules-load.service local-fs.target
Conflicts=shutdown.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=iptables-restore --noflush --table mangle /etc/iptables/rules.v4
ExecStop=/bin/true

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable local-iptables.service
sudo systemctl start local-iptables.service

# disable systemd-resolvd as it breaks coredns & kubelet resolving
# https://coredns.io/plugins/loop/#troubleshooting
# https://askubuntu.com/questions/907246/how-to-disable-systemd-resolved-in-ubuntu

# sudo cat /etc/resolve.conf  (TODO: Ask Arne about what this is doing)
sudo rm -f -- /etc/resolv.conf
sudo grep ^nameserver /run/systemd/resolve/resolv.conf > /etc/resolv.conf 
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved

waitforapt
sudo apt-get -qq update
sudo apt-get -qq install -y vim
sudo echo 'set mouse=' > /root/.vimrc
sudo echo 'PasswordAuthentication no' >> /etc/ssh/sshd_config
sudo systemctl restart sshd

sudo apt-get -qy install \
%{for install_package in install_packages~}
	${install_package} \
%{endfor~}

# install docker
sudo echo "
Package: docker-ce
Pin: version ${docker_version}.*
Pin-Priority: 1000
" > /etc/apt/preferences.d/docker-ce
waitforapt
# sudo apt-get -qq -y remove docker docker-engine docker.io containerd runc
sudo apt-get -qq update
sudo apt-get -qq install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
# sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

#   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
#  "deb [arch=amd64] https://download.docker.com/linux/debian \
#   $(lsb_release -cs) \
#   stable"

echo "added docker repo to repository list..."

sudo apt-get -qq update && apt-get -qq install -y docker-ce

sudo cat > /etc/docker/daemon.json <<EOF
{
  "storage-driver":"overlay2"
}
EOF

sudo systemctl restart docker.service

# install kubernetes
sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
sudo cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

sudo echo "
Package: kubelet
Pin: version ${kubernetes_version}-*
Pin-Priority: 1000
" > /etc/apt/preferences.d/kubelet

sudo echo "
Package: kubeadm
Pin: version ${kubernetes_version}-*
Pin-Priority: 1000
" > /etc/apt/preferences.d/kubeadm

waitforapt
sudo apt-get -qq update
sudo apt-get -qq install -y kubelet kubeadm

sudo mv -v ${server_upload_dir}/10-kubeadm.conf /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

sudo systemctl daemon-reload
sudo systemctl restart kubelet