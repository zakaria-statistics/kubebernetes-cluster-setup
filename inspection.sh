#!/bin/bash

# Set the kubeconfig if it's not already set
export KUBECONFIG=/etc/kubernetes/admin.conf

echo "Using kubeconfig: $KUBECONFIG"
echo "---------------------------------------------"

# 2. Checking logs for kube-apiserver, kube-controller-manager, and etcd
echo "Checking logs for Kubernetes components..."
for pod in kube-apiserver kube-controller-manager etcd; do
    echo "Fetching last 10 lines of logs for $pod..."
    kubectl logs -n kube-system -l component=$pod --tail=10 || { echo "Failed to fetch logs for $pod."; exit 1; }
done
echo "---------------------------------------------"

# 3. Checking the status of nodes
echo "Checking Node status..."
kubectl get nodes || { echo "Failed to get nodes."; exit 1; }
echo "---------------------------------------------"

# 4. Checking services
echo "Checking services in kube-system namespace..."
kubectl get svc -n kube-system || { echo "Failed to get services in kube-system."; exit 1; }
echo "---------------------------------------------"

# 5. Checking deployments
echo "Checking deployments in kube-system namespace..."
kubectl get deployments -n kube-system || { echo "Failed to get deployments in kube-system."; exit 1; }
echo "---------------------------------------------"

# 6. Checking pods in kube-system namespace
echo "Checking pods in kube-system namespace..."
kubectl get pods -n kube-system || { echo "Failed to get pods in kube-system."; exit 1; }
echo "---------------------------------------------"

# 7. Checking pods in default namespace
echo "Checking pods in default namespace..."
kubectl get pods || { echo "Failed to get pods in default namespace."; exit 1; }
echo "---------------------------------------------"

# 8. Check if all nodes are in Ready state
echo "Checking if all nodes are in Ready state..."
kubectl get nodes --no-headers | grep "Ready" || echo "No nodes are in Ready state."
echo "---------------------------------------------"

# 9. Check network policies (if applicable)
echo "Checking network policies..."
kubectl get netpol || echo "No network policies found."
echo "---------------------------------------------"

# 10. Checking if required ports are open on the local machine
echo "Checking if required ports are open..."
sudo netstat -tuln | grep -E '6443|10250|2379|2380|10251|10252' || { echo "Required ports are not open."; exit 1; }
echo "---------------------------------------------"

# 11. Checking for taints
echo "Checking for taints on nodes..."
kubectl describe nodes | grep -i taints || echo "No taints found."
echo "---------------------------------------------"

# 12. Ensure that AppArmor is stopped and disabled
echo "Verifying AppArmor status..."
if systemctl is-active --quiet apparmor; then
    echo "Stopping AppArmor..."
    sudo systemctl stop apparmor
    sudo systemctl disable apparmor
else
    echo "AppArmor is already stopped."
fi
echo "---------------------------------------------"

# 13. Verifying the API server is reachable
echo "Verifying the API server is reachable..."
curl -k https://127.0.0.1:6443 || { echo "Failed to reach the API server."; exit 1; }
echo "---------------------------------------------"

echo "Inspection completed successfully."
