#!/bin/bash
MANAGER_IP=192.168.6.1
sudo apt-get update
sudo apt-get -y install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get -y install docker-ce docker-ce-cli containerd.io

sudo curl -L "https://github.com/docker/compose/releases/download/2.4.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

TOKEN=$(sudo ssh -o StrictHostKeyChecking=no -p 22 "root@node0" "docker swarm join-token --quiet manager")
while [[ $TOKEN != SWMTKN* ]]
do
    echo "waiting for manager node to create the swarm..."
    sleep 5
    TOKEN=$(sudo ssh -o StrictHostKeyChecking=no -p 22 "root@node0" "docker swarm join-token --quiet manager")
done
TOKEN=$(sudo ssh -o StrictHostKeyChecking=no -p 22 "root@node0" "docker swarm join-token --quiet manager")
sudo docker swarm join --token $TOKEN $MANAGER_IP:2377

sudo modprobe mpls_router
