#!/bin/bash
MANAGER_IP=192.168.6.1
sudo apt-get update
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu `lsb_release -cs` test"
sudo apt update
sudo apt install docker-ce
sudo apt-get -y install docker-ce docker-ce-cli containerd.io

TOKEN=$(ssh -o StrictHostKeyChecking=no -p 22 "root@node0" "docker swarm join-token --quiet worker")
sudo docker swarm join --token $TOKEN $MANAGER_IP:2377
sudo modprobe mpls_router