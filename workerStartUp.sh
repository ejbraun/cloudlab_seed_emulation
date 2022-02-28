#!/bin/bash
MANAGER_IP=192.168.6.1
sudo apt-get update
sudo apt-get -qq --no-install-recommends install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/debian `lsb_release -cs` stable\"
sudo apt-get update
sudo apt-get -qq --no-install-recommends install docker-ce docker-ce-cli containerd.io docker-compose
TOKEN=$(ssh -p 22 "root@$MANAGER_IP" "docker swarm join-token --quiet worker"))
sudo docker swarm join --token $TOKEN $MANAGER_IP:2377
sudo modprobe mpls_router