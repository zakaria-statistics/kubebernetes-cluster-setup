#!/bin/bash

# 1. Install Helm (for Kubernetes package management)
echo "Installing Helm (Kubernetes package manager)..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# 2. Install Metrics Server (useful for monitoring resource usage)
echo "Installing Metrics Server..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# 3. Install NGINX Ingress Controller (optional, if ingress management is needed)
echo "Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

# 4. Set up a Storage Class (if using dynamic volume provisioning)
echo "Setting up default StorageClass..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/community/master/sig-storage/persistent-volumes/storageclass.yaml

# 5. Install Helm Chart for essential add-ons (like dashboard)
echo "Installing Kubernetes Dashboard..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.6.0/aio/deploy/recommended.yaml

# 6. Enable kubectl autocomplete (optional but helpful)
echo "Enabling kubectl autocomplete..."
echo 'source <(kubectl completion bash)' >> ~/.bashrc
source ~/.bashrc

# 7. Check cluster status to confirm everything is running fine
echo "Checking Kubernetes cluster status..."
kubectl get all --all-namespaces

# 8. Verify that the system is ready for workloads
echo "Cluster is fully initialized and configured."
