1) Truy cập control-node
Trên máy Windows (PowerShell): docker exec -it control-node bash

2) Cài Ansible (trong control-node)
apt-get update
apt-get install -y python3 python3-pip openssh-client sshpass
pip install ansible
ansible --version

