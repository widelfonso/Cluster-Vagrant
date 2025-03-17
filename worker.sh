#!/bin/bash

start_time=$(date +%s)  # Captura o tempo inicial

set -e

# Atualizando pacotes e instalando dependências
echo "Atualizando pacotes e instalando dependências..."
sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# Configuração do Kubernetes
echo "Configurando Kubernetes..."
sudo swapoff -a
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo modprobe overlay
sudo modprobe br_netfilter
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system

# Adicionando repositório do Kubernetes
echo "Adicionando repositório do Kubernetes..."
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Instalando containerd
echo "Instalando containerd..."
sudo apt-get update
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt-get update

sudo apt-get install -y containerd.io

sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl status containerd


# Esperando o master gerar o token de junção
while [ ! -f /vagrant/join-command.sh ]; do
  echo "Aguardando o master gerar o comando de join..."
  sleep 10
done

# Ingressando no cluster
sudo bash /vagrant/join-command.sh

end_time=$(date +%s)  # Captura o tempo final
elapsed_time=$((end_time - start_time))  # Calcula a duração
echo "###################################################"
echo "# Tempo total de espera: ${elapsed_time} segundos #"
echo "###################################################"