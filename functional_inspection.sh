#!/bin/bash

# Set the kubeconfig file to access Kubernetes
KUBECONFIG="/etc/kubernetes/admin.conf"

# Function to check if a command was successful
check_success() {
  if [ $? -ne 0 ]; then
    echo "Error: $1 failed."
    exit 1
  fi
}

# Function to check the logs of a Kubernetes component
fetch_logs() {
  COMPONENT=$1
  echo "Fetching last 10 lines of logs for $COMPONENT..."
  kubectl logs -n kube-system -l component=$COMPONENT --tail=10
  check_success "Fetching logs for $COMPONENT"
}

# Check if the kubeconfig is set correctly
echo "Using kubeconfig: $KUBECONFIG"

# Check the logs of Kubernetes components (apiserver, controller-manager, etcd)
echo "Checking logs for Kubernetes components..."
fetch_logs "kube-apiserver"
fetch_logs "kube-controller-manager"
fetch_logs "etcd"

# Check the status of nodes
echo "Checking Node status..."
kubectl get nodes
check_success "Checking Node status"

# Check services in kube-system namespace
echo "Checking services in kube-system namespace..."
kubectl get services -n kube-system
check_success "Checking services in kube-system namespace"

# Check deployments in kube-system namespace
echo "Checking deployments in kube-system namespace..."
kubectl get deployments -n kube-system
check_success "Checking deployments in kube-system namespace"

# Check pods in kube-system namespace
echo "Checking pods in kube-system namespace..."
kubectl get pods -n kube-system
check_success "Checking pods in kube-system namespace"

# Check pods in default namespace
echo "Checking pods in default namespace..."
kubectl get pods -n default
check_success "Checking pods in default namespace"

# Check if all nodes are in Ready state
echo "Checking if all nodes are in Ready state..."
kubectl get nodes --no-headers | awk '{print $2}' | grep -v "Ready"
check_success "Checking if all nodes are in Ready state"

# Check network policies in default namespace
echo "Checking network policies in default namespace..."
kubectl get networkpolicies -n default
check_success "Checking network policies in default namespace"

# Check if required ports are open
echo "Checking if required ports are open..."
ss -tuln | grep -E '2380|2379|10250|6443'
check_success "Checking if required ports are open"

# Check for taints on nodes
echo "Checking for taints on nodes..."
kubectl describe nodes | grep -i taints
check_success "Checking for taints on nodes"

# Verifying AppArmor status
echo "Verifying AppArmor status..."
systemctl is-active --quiet apparmor && echo "AppArmor is running" || echo "AppArmor is already stopped."

# Verifying the API server is reachable
echo "Verifying the API server is reachable..."
curl --silent --max-time 5 https://127.0.0.1:6443/healthz > /dev/null
if [ $? -eq 0 ]; then
  echo "API server is reachable."
else
  echo "API server is not reachable."
fi

echo "Inspection completed successfully."
