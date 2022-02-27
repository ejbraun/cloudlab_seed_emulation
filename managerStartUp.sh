#!/bin/bash
sudo apt-get update
sudo apt-get -qq --no-install-recommends install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/debian `lsb_release -cs` stable\"
sudo apt-get update
sudo apt-get -qq --no-install-recommends install docker-ce docker-ce-cli containerd.io docker-compose
sudo docker swarm init
sudo modprobe mpls_router