#!/bin/bash

# Ensure you run as root or with sudo privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

echo "Cleaning up Kubernetes environment..."

# Step 1: Reset Kubernetes cluster with kubeadm
echo "Running kubeadm reset..."
sudo kubeadm reset -f

# Step 2: Remove Kubernetes, containerd, and CNI related files
echo "Removing Kubernetes configuration and data..."
sudo rm -rf /etc/kubernetes/
sudo rm -rf /var/lib/etcd/
sudo rm -rf /var/lib/kubelet/
sudo rm -rf /var/lib/cni/
sudo rm -rf /opt/cni/bin/
sudo rm -rf $HOME/.kube/

# Step 3: Clean iptables rules
echo "Cleaning iptables..."
sudo iptables -F
sudo iptables -X
sudo iptables -t nat -F
sudo iptables -t nat -X
sudo iptables -t raw -F
sudo iptables -t raw -X
sudo iptables -t mangle -F
sudo iptables -t mangle -X

# Step 4: Stop containerd and clean its data (only if using containerd)
echo "Stopping containerd service..."
sudo systemctl stop containerd
echo "Removing containerd data..."
sudo rm -rf /var/lib/containerd/

# Step 5: Restart containerd service (if using containerd)
echo "Restarting containerd service..."
sudo systemctl restart containerd

# Step 6: Stop and restart kubelet
echo "Stopping kubelet service..."
sudo systemctl stop kubelet
echo "Starting kubelet service..."
sudo systemctl start kubelet

# Step 7: Disable AppArmor (if needed)
echo "Disabling AppArmor (if necessary)..."
sudo systemctl stop apparmor
sudo systemctl disable apparmor

# Step 8: Optional - Restart system for complete cleanup
echo "Restarting the system (optional)..."
# sudo reboot

echo "Cleaning process completed. Your system is ready for a fresh Kubernetes installation."
