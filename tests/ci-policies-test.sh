#!/bin/bash
echo "Install k3s cluster..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='--flannel-backend=none --disable traefik' sh -s - --write-kubeconfig-mode 644
          
echo "Make k3s cluster config default..."
mkdir ~/.kube
cp /etc/rancher/k3s/k3s.yaml ~/.kube/config

echo "Install helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "Install karmor..."
curl -sfL https://raw.githubusercontent.com/kubearmor/kubearmor-client/main/install.sh | sudo sh -s -- -b /usr/local/bin

echo "Install cilium cli tool..."
curl -L --remote-name-all https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz{,.sha256sum}
echo "Checking for cilium tar file..."
sha256sum --check cilium-linux-amd64.tar.gz.sha256sum
echo "Extracting the tar file..."
sudo tar xzvfC cilium-linux-amd64.tar.gz /usr/local/bin
echo "Removing the tar file..."
rm cilium-linux-amd64.tar.gz{,.sha256sum}

echo "Install Daemonsets and Services..."
curl -s https://raw.githubusercontent.com/accuknox/tools/main/install.sh | bash
          
echo "Waiting for kubearmor-relay to be ready..."
kubectl wait --for=condition=ready pod -l kubearmor-app=kubearmor-relay --timeout=60s --namespace kube-system
echo "Waiting for kubearmor to be ready..."
kubectl wait --for=condition=ready pod -l kubearmor-app=kubearmor --timeout=60s --namespace kube-system
echo "Waiting for kubearmor-policy-manager to be ready..."
kubectl wait --for=condition=ready pod -l kubearmor-app=kubearmor-policy-manager --timeout=60s --namespace kube-system
echo "Waiting for kubearmor-host-policy-manager to be ready..."
kubectl wait --for=condition=ready pod -l kubearmor-app=kubearmor-host-policy-manager --timeout=60s --namespace kube-system
echo "Waiting for knoxautopolicy to be ready..."
kubectl wait --for=condition=ready pod -l container=knoxautopolicy --timeout=60s --namespace explorer

echo "Checking status..."
kubectl get pods -A

echo "Waiting for hubble-relay to be ready..."
kubectl wait --for=condition=ready pod -l k8s-app=hubble-relay --timeout=60s --namespace kube-system

echo "Install sample k8s application..."
kubectl apply -f https://raw.githubusercontent.com/kubearmor/KubeArmor/main/examples/wordpress-mysql/wordpress-mysql-deployment.yaml
echo "Waiting for wordpress to be ready..."
kubectl wait --for=condition=ready pod -l app=wordpress --timeout=60s --namespace wordpress-mysql
echo "Waiting for mysql to be ready..."
kubectl wait --for=condition=ready pod -l app=mysql --timeout=60s --namespace wordpress-mysql

echo "Checking status..."
kubectl get pods -A

sleep 120

echo "Get Auto discovered policies..."
curl -s https://raw.githubusercontent.com/accuknox/tools/main/get_discovered_yamls.sh | bash
