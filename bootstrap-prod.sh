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
echo "Verifying Helm installation"
helm version

echo "Setting up kubeconfig"    
kubectl config use-context $CLUSTERNAME   

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

        echo "fails even before creating created secret"
        HOSTINGERAPIKEY=$(printf "%s" "$HOSTINGERAPIKEY" | tr -d '\r\n')


        kubectl create secret generic hostinger-credentials \
         --from-literal="apiToken=$HOSTINGERAPIKEY" \
           --namespace=cert-manager --dry-run=client -o yaml | kubectl apply -f -


echo "Applying certificate and issuer files"
EXPORT EMAIL
envsubst < helm/cert-manager/clusterissuer.yaml | kubectl apply -f -
kubectl apply -f helm/cert-manager/certificate.yaml
