#!/bin/bash

# Set the kubeconfig if it's not already set
export KUBECONFIG=/etc/kubernetes/admin.conf

# Log file for errors and warnings
LOGFILE="/var/log/kubernetes_inspection.log"
# Empty the log file if it exists
if [ -f "$LOGFILE" ]; then
    echo "Emptying the log file: $LOGFILE"
    > "$LOGFILE"  # Truncate the log file
fi

echo "Using kubeconfig: $KUBECONFIG" | tee -a $LOGFILE
echo "---------------------------------------------" | tee -a $LOGFILE

# Function to log only errors and warnings (stderr)
log_error_warning() {
    local command="$1"
    local label="$2"
    echo "---------------------------------------------" | tee -a $LOGFILE
    echo "Running: $label" | tee -a $LOGFILE
    eval $command 2>> $LOGFILE
    if [ $? -ne 0 ]; then
        echo "ERROR: $label failed. Check $LOGFILE for details." | tee -a $LOGFILE
    else
        echo "$label completed successfully." | tee -a $LOGFILE
    fi
}

# 2. Checking logs for kube-apiserver, kube-controller-manager, and etcd
echo "Checking logs for Kubernetes components..." | tee -a $LOGFILE
for pod in kube-apiserver kube-controller-manager etcd; do
    log_error_warning "kubectl logs -n kube-system -l component=$pod --tail=10" "Logs for $pod"
done
echo "---------------------------------------------" | tee -a $LOGFILE

# 3. Checking the status of nodes
log_error_warning "kubectl get nodes" "Node status check"
echo "---------------------------------------------" | tee -a $LOGFILE

# 4. Checking services
log_error_warning "kubectl get svc -n kube-system" "Checking services in kube-system namespace"
echo "---------------------------------------------" | tee -a $LOGFILE

# 5. Checking deployments
log_error_warning "kubectl get deployments -n kube-system" "Checking deployments in kube-system namespace"
echo "---------------------------------------------" | tee -a $LOGFILE

# 6. Checking pods in kube-system namespace
log_error_warning "kubectl get pods -n kube-system" "Checking pods in kube-system namespace"
echo "---------------------------------------------" | tee -a $LOGFILE

# 7. Checking pods in default namespace
log_error_warning "kubectl get pods" "Checking pods in default namespace"
echo "---------------------------------------------" | tee -a $LOGFILE

# 8. Check if all nodes are in Ready state
echo "Checking if all nodes are in Ready state..." | tee -a $LOGFILE
kubectl get nodes --no-headers | grep "Ready" >> $LOGFILE
if [ $? -ne 0 ]; then
    echo "ERROR: No nodes are in Ready state." | tee -a $LOGFILE
else
    echo "All nodes are in Ready state." | tee -a $LOGFILE
fi
echo "---------------------------------------------" | tee -a $LOGFILE

# 9. Check network policies (if applicable)
log_error_warning "kubectl get netpol" "Checking network policies"
echo "---------------------------------------------" | tee -a $LOGFILE

# 10. Checking if required ports are open on the local machine
echo "Checking if required ports are open..." | tee -a $LOGFILE
sudo netstat -tuln | grep -E '6443|10250|2379|2380|10251|10252' >> $LOGFILE
if [ $? -ne 0 ]; then
    echo "ERROR: Required ports are not open." | tee -a $LOGFILE
else
    echo "Required ports are open." | tee -a $LOGFILE
fi
echo "---------------------------------------------" | tee -a $LOGFILE

# 11. Checking for taints
log_error_warning "kubectl describe nodes | grep -i taints" "Checking for taints on nodes"
echo "---------------------------------------------" | tee -a $LOGFILE

# 12. Ensure that AppArmor is stopped and disabled
echo "Verifying AppArmor status..." | tee -a $LOGFILE
if systemctl is-active --quiet apparmor; then
    echo "Stopping AppArmor..." | tee -a $LOGFILE
    sudo systemctl stop apparmor >> $LOGFILE 2>&1
    sudo systemctl disable apparmor >> $LOGFILE 2>&1
else
    echo "AppArmor is already stopped." | tee -a $LOGFILE
fi
echo "---------------------------------------------" | tee -a $LOGFILE

# 13. Verifying the API server is reachable
echo "Verifying the API server is reachable..." | tee -a $LOGFILE
curl -k https://127.0.0.1:6443 >> $LOGFILE 2>&1
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to reach the API server." | tee -a $LOGFILE
else
    echo "API server is reachable." | tee -a $LOGFILE
fi
echo "---------------------------------------------" | tee -a $LOGFILE

echo "Inspection completed successfully." | tee -a $LOGFILE
