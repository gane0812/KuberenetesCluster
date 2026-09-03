#!/bin/bash

set -e
echo "Installing Kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

chmod +x kubectl
sudo mv kubectl /usr/local/bin/

echo "Verifying Kubectl installation"
kubectl version --client
echo "Installing Helm"
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4
chmod 700 get_helm.sh
./get_helm.sh

echo "Setting up kubeconfig"    
kubectl config use-context $CLUSTERNAME   

echo "Checking Changes/ Applying resources"
kubectl apply -R -f app/