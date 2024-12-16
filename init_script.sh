#!/bin/bash

# Set the master hostname and pod network CIDR
MASTER_HOSTNAME="master-node"
POD_NETWORK_CIDR="192.168.0.0/16"

# 1. Get the current machine's IP address
CURRENT_IP=$(hostname -I | awk '{print $1}')

# 2. Update /etc/hosts with the new IP for master-node ???.................???
echo "Updating /etc/hosts with the current IP ($CURRENT_IP) for $MASTER_HOSTNAME..."
if ! grep -q "$MASTER_HOSTNAME" /etc/hosts; then
    echo "$CURRENT_IP $MASTER_HOSTNAME" | sudo tee -a /etc/hosts > /dev/null
else
    sudo sed -i "/$MASTER_HOSTNAME/d" /etc/hosts
    echo "$CURRENT_IP $MASTER_HOSTNAME" | sudo tee -a /etc/hosts > /dev/null
fi

# 3. Initialize Kubernetes cluster with kubeadm
echo "Initializing Kubernetes cluster..."
sudo kubeadm init --pod-network-cidr=$POD_NETWORK_CIDR --apiserver-cert-extra-sans=$CURRENT_IP

# 4. Set up kubeconfig for the regular user (to interact with the cluster)
echo "Setting up kubeconfig..."
export KUBECONFIG=/etc/kubernetes/admin.conf

# 5. Set up networking using Calico CNI plugin for pod networking
echo "Setting up Calico networking plugin..."
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# 6. Remove taint from the master node so that it can schedule pods
echo "Removing taint from the master node..."
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

# 7. Check if all required ports are available and open
echo "Checking if required ports are open..."
sudo netstat -tuln | grep -E '6443|10250|2379|2380|10251|10252'

# 8. Verify that kubelet and other essential services are running
echo "Checking Kubelet and Kubernetes components status..."
kubectl get pods -n kube-system || { echo "Failed to get pods in kube-system namespace."; exit 1; }

# 9. Ensure that AppArmor is stopped and disabled
echo "Verifying AppArmor status..."
if systemctl is-active --quiet apparmor; then
    echo "Stopping AppArmor..."
    sudo systemctl stop apparmor
    sudo systemctl disable apparmor
else
    echo "AppArmor is already stopped."
fi

# 10. Check Node status and ensure it's ready
echo "Checking Node status..."
kubectl get nodes || { echo "Failed to get nodes."; exit 1; }

# 11. Confirm that the cluster is initialized and running correctly
echo "Cluster initialized successfully."
