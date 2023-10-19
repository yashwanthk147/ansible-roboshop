#!/bin/bash

set -euxo pipefail

# disable swap
sudo swapoff -a

#keep the swapoff while reboot
(crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | crontab - || true
sudo apt-get update -y

# IPtables to see bridged traffic

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf 
      overlay 
      br_netfilter 
   EOF 

sudo modprobe overlay 
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf 
     net.bridge.bridge-nf-call-iptables = 1 
     net.bridge.bridge-nf-call-ip6tables = 1
     net.ipv4.ip_forward = 1 
   EOF 

# Apply sysctl params without reboot
sudo sysctl --system

cat <<EOF | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/
stable/xUbuntu_22.04/ /
EOF
cat <<EOF | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:
cri-o:1.26.list
deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:
/cri-o:/1.26/xUbuntu_22.04/ /
EOF

curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:
cri-o:1.26/xUbuntu_22.04/Release.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/
libcontainers.gpg add -
curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/
xUbuntu_22.04/Release.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers.
gpg add -
sudo apt-get update

#Install docker
sudo apt install docker.io
sudo systemctl start docker
sudo systemctl enable docker

#Install CRI-O runtime
sudo apt-get install cri-o cri-o-runc -y

sudo systemctl daemon-reload
sudo systemctl enable crio --now
sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl

#Retrieve the key for the Kubernetes repo and add it to your key manager
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

#Add the kubernetes repo to your system
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

# Install kubelet, kubectl and Kubeadm
sudo apt-get update -y
sudo apt-get install -y kubelet=1.26.3-00 kubectl=1.26.3-00 kubeadm=1.26.3-00
sudo apt-get update -y
sudo apt-get install -y jq

#Add the node IP to <code>KUBELET_EXTRA_ARGS</code>
local_ip="$(ip --json a s | jq -r '.[] | if .ifname == "eth1" then .addr_info[] | 
if .family == "inet" then .local else empty end else empty end')"
cat > /etc/default/kubelet << EOF
KUBELET_EXTRA_ARGS=--node-ip=$local_ip
EOF

