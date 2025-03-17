#!/bin/bash

start_time=$(date +%s)  # Captura o tempo inicial

set -e

# Atualizando pacotes e instalando dependências 
echo "#################################################"
echo "# Atualizando pacotes e instalando dependências #"
echo "#################################################"
sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# Configuração do Kubernetes
echo "##############################"
echo "# Configurando Control Plane #"
echo "##############################"
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
echo "#########################################"
echo "# Adicionando repositório do Kubernetes #"
echo "#########################################"
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Instalando containerd
echo "#########################"
echo "# Instalando containerd #"
echo "#########################"
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

# Definições
KUBEADM_LOG="/home/vagrant/kubeadm-init.log"
KUBE_DIR="/home/vagrant/.kube"

# Inicializando o cluster Kubernetes
echo "######################################"
echo "# Inicializando o cluster Kubernetes #"
echo "######################################"

if sudo kubeadm init --pod-network-cidr=10.10.0.0/16 --apiserver-advertise-address=192.168.56.31 | tee "$KUBEADM_LOG"; then
    echo "Cluster inicializado com sucesso!"
else
    echo "Falha ao inicializar o cluster. Verifique o log em $KUBEADM_LOG"
    exit 1
fi


# Configurando kubectl para o usuário vagrant
echo "###############################################"
echo "# Configurando kubectl para o usuário vagrant #"
echo "###############################################"

if [ -d "$KUBE_DIR" ]; then
    rm -rf "$KUBE_DIR"
fi
mkdir -p "$KUBE_DIR"
sudo cp -i /etc/kubernetes/admin.conf "$KUBE_DIR/config"
sudo chown vagrant:vagrant "$KUBE_DIR/config"

# Exporta o kubeconfig para garantir que o kubectl use a configuração correta
export KUBECONFIG=/etc/kubernetes/admin.conf

#Aguardar API Server estar pronto antes de instalar a rede de pods
echo "Aguardando o API Server estar disponível..."

# start_time=$(date +%s)  # Captura o tempo inicial

# for i in {1..30}; do  # Tentativa por até 5 minutos (10s * 30)
#     if kubectl get nodes --no-headers 2>/dev/null | grep -q ' Ready'; then
#         echo "API Server está pronto!"
#         break
#     fi
#     echo "Aguardando mais 10 segundos..."
#     sleep 10
# done

# end_time=$(date +%s)  # Captura o tempo final
# elapsed_time=$((end_time - start_time))  # Calcula a duração

# echo "Tempo total de espera: ${elapsed_time} segundos"

#Instalando rede de pods (Weave Net)
echo "#########################################"
echo "# Instalando a rede de pods (Weave Net) #"
echo "#########################################"

if kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml --validate=false; then
    echo "Rede de pods instalada com sucesso!"
else
    echo "Falha ao instalar a rede de pods."
    exit 1
fi

# Extraindo token para os 
echo "###################################"
echo "# Extraindo token para os workers #"
echo "###################################"

if [ -f /vagrant/join-command.sh ]; then
    echo "Arquivo join-command.sh encontrado. Removendo..."
    rm /vagrant/join-command.sh
fi
kubeadm token create --print-join-command | tee /vagrant/join-command.sh
chmod +x /vagrant/join-command.sh

echo "##########################################"
echo "##########################################"
echo "# Control Plane configurado com sucesso! #"
echo "##########################################" 
echo "##########################################"

end_time=$(date +%s)  # Captura o tempo final
elapsed_time=$((end_time - start_time))  # Calcula a duração
echo "###################################################"
echo "# Tempo total de espera: ${elapsed_time} segundos #"
echo "###################################################"

# Salva o tempo de execução no arquivo de log
echo "Tempo total de execução: ${elapsed_time} segundos" >> kubeadm-init.log
