#!/bin/bash

# check_resources.sh
# This script checks system resources, prerequisites, and components for Kubernetes initialization.

echo "Starting system checks for Kubernetes initialization..."

# 1. Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: Please run as root or with sudo."
    exit 1
fi

# 2. Get the current machine's IP address
CURRENT_IP=$(hostname -I | awk '{print $1}')
if [ -z "$CURRENT_IP" ]; then
    echo "Error: Unable to determine the current IP address."
    exit 1
fi
echo "Current IP address: $CURRENT_IP"

# 3. Check if required commands are available
REQUIRED_CMDS=("kubeadm" "kubectl" "kubelet" "containerd" "sed" "netstat" "lsof")
echo "Checking for required commands..."
for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: Required command '$cmd' is not installed."
        exit 1
    fi
done
echo "All required commands are available."

# 4. Check Kubernetes services
echo "Checking if Kubernetes services are enabled and running..."
KUBELET_STATUS=$(systemctl is-active kubelet)
if [ "$KUBELET_STATUS" != "active" ]; then
    echo "Error: kubelet service is not running."
else
    echo "kubelet service is running."
fi

# 5. Check if containerd is running
echo "Checking if containerd service is enabled and running..."
CONTAINERD_STATUS=$(systemctl is-active containerd)
if [ "$CONTAINERD_STATUS" != "active" ]; then
    echo "Error: containerd service is not running."
    exit 1
else
    echo "containerd service is running."
fi

# 6. Check system resources (minimum 2 CPU cores and 2GB RAM)
CPU_CORES=$(nproc)
RAM_MB=$(free -m | awk '/^Mem:/{print $2}')

if [ "$CPU_CORES" -lt 2 ]; then
    echo "Error: At least 2 CPU cores are required."
    exit 1
fi

if [ "$RAM_MB" -lt 2048 ]; then
    echo "Error: At least 2GB of RAM is required."
    exit 1
fi

echo "System resources check passed: $CPU_CORES CPU cores, $RAM_MB MB RAM"

# 7. Check for required ports (6443, 10250, 2379, 2380, 10251, 10252)
REQUIRED_PORTS=(6443 10250 2379 2380 10251 10252)
echo "Checking required ports..."
for port in "${REQUIRED_PORTS[@]}"; do
    if sudo lsof -i -P -n | grep ":$port" &> /dev/null; then
        echo "Error: Port $port is already in use."
        exit 1
    fi
done
echo "All required ports are free."

# 8. Check if AppArmor is active
if systemctl is-active --quiet apparmor; then
    echo "AppArmor is active. It may need to be stopped before initialization."
else
    echo "AppArmor is not active."
fi

# 9. Verify that swap is disabled
echo "Checking if swap is disabled..."
if swapon --show | grep -q "swap"; then
    echo "Error: Swap is enabled. Please disable it using 'swapoff -a'."
    exit 1
else
    echo "Swap is disabled."
fi

# 10. Check for CNI plugins
if [ -d "/opt/cni/bin/" ] && [ "$(ls -A /opt/cni/bin/)" ]; then
    echo "CNI plugins are installed."
else
    echo "Error: CNI plugins are not installed. Please install them."
fi

# 11. Check containerd config file
if [ -f "/etc/containerd/config.toml" ]; then
    echo "containerd configuration found."
else
    echo "Error: containerd configuration file is missing."
    exit 1
fi

echo "All checks passed. The system is ready for Kubernetes initialization."
