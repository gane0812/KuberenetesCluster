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

#
echo "Verifying Helm installation"
helm version

if command -v docker >/dev/null 2>&1; then
	echo "Docker is already installed"
else
	echo "Installing Docker"
	curl -fsSL https://get.docker.com | sudo sh
fi

echo "Verifying Docker installation"
docker --version

echo "Installing k3d"
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

echo "Verifying k3d installation"
k3d version

echo "Create k3d Cluster "
k3d cluster create k8s \
  --port 80:80@loadbalancer \
  --port 443:443@loadbalancer \
  --port 8000:8000@loadbalancer \
  --k3s-arg "--disable=k8s@server:0"

echo "Setting up kubeconfig for k3d cluster"    
kubectl config use-context k3d-k8s   

echo "Installing Kubernetes Gateway CRDs"
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.6.1/standard-install.yaml

echo "Generating self-signed TLS certificate"

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=*.ganeshsaravanan.online"

echo "Creating TLS secret"
kubectl create secret tls ganeshsaravanan-tls \
  --cert=tls.crt --key=tls.key  


echo "Installing Traefik using Helm"
helm repo add traefik https://traefik.github.io/charts
helm repo update 

helm install traefik traefik/traefik \
  --values helm/traefik/values.yaml

echo "Installing Cert-Manager using Helm"
helm install \
  cert-manager oci://quay.io/jetstack/charts/cert-manager \
  --version v1.21.1 \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true

echo "Installing Hostinger webhook for Cert-Manager"
helm install hostinger-webhook oci://ghcr.io/lokinado/cert-manager-webhook-hostinger \
    --namespace cert-manager \
    --set groupName='acme.ganeshsaravanan.online'

set -x
echo "Length of key: ${#HOSTINGERAPIKEY}"
kubectl create secret generic hostinger-credentials \
  --from-literal=apiToken='xiKYO7m06erElk8oMvkXFbV9JZXh9me7GaNd23Y76a896394' \
  --namespace=cert-manager
set +x

kubectl apply -f helm/cert-manager/clusterissuer.yaml
kubectl apply -f helm/cert-manager/certificate.yaml
