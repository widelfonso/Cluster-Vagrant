# Kubernetes Cluster Setup with Vagrant

Este projeto configura um cluster Kubernetes usando Vagrant e VirtualBox. O cluster consiste em um nó de controle (control-plane) e dois nós de trabalho (workers).

## Estrutura do Projeto

- `.vagrant/rgloader/loader.rb`: Arquivo de configuração do Vagrant.
- `join-command.sh`: Script gerado pelo nó de controle para que os nós de trabalho possam ingressar no cluster.
- `master.sh`: Script de configuração do nó de controle.
- `Vagrantfile`: Arquivo de configuração do Vagrant para definir as VMs do cluster.
- `worker.sh`: Script de configuração dos nós de trabalho.

## Pré-requisitos

- [Vagrant](https://www.vagrantup.com/downloads)
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads)

## Como Usar

1. Clone este repositório:
    ```sh
    git clone https://github.com/RaphaelOhlsen/Kubernetes_Vagrant
    cd Kubernetes_Vagrant
    ```

2. Inicie o cluster:
    ```sh
    vagrant up
    ```

3. Acesse o nó de controle:
    ```sh
    vagrant ssh control-plane
    ```

4. Verifique o status do cluster:
    ```sh
    kubectl get nodes
    ```

## Scripts

### [worker.sh](http://_vscodecontentref_/0)

Este script configura os nós de trabalho:

- Atualiza pacotes e instala dependências.
- Configura o Kubernetes.
- Adiciona o repositório do Kubernetes.
- Instala o containerd.
- Aguarda o comando de junção gerado pelo nó de controle.
- Ingressa no cluster usando o comando de junção.

## Licença

Este projeto está licenciado sob a licença MIT. Veja o arquivo LICENSE para mais detalhes.