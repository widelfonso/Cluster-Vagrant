Vagrant.configure("2") do |config|
    # Configuração do master
    config.vm.define "control-plane" do |master|
      master.vm.box = "ubuntu/jammy64"
      master.vm.hostname = "master-1"
      worker.vm.network "private_network", ip: "192.168.56.31"
  
      master.ssh.insert_key = false
      master.ssh.private_key_path = ['~/.vagrant.d/insecure_private_key', '~/.ssh/id_rsa']
      master.vm.provision "file", source: "~/.ssh/id_rsa.pub", destination: "~/.ssh/authorized_keys"  
  
      master.vm.provider "virtualbox" do |vb|
        vb.memory = "2048"
        vb.cpus = 2
      end
      master.vm.provision "shell", path: "master.sh"
    end
  
    # Configuração dos workers (nós)
    (1..2).each do |i|
      config.vm.define "worker-#{i}" do |worker|
        worker.vm.box = "ubuntu/jammy64"
        worker.vm.hostname = "worker-#{i}"
        worker.vm.network "private_network", ip: "192.168.56.#{31 + i}"
  
        worker.ssh.insert_key = false
        worker.ssh.private_key_path = ['~/.vagrant.d/insecure_private_key', '~/.ssh/id_rsa']
        worker.vm.provision "file", source: "~/.ssh/id_rsa.pub", destination: "~/.ssh/authorized_keys"
  
        worker.vm.provider "virtualbox" do |vb|
          vb.memory = "2048"
          vb.cpus = 2
        end
        worker.vm.provision "shell", path: "worker.sh"
      end
    end
  end