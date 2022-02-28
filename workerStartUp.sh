#!/bin/bash
MANAGER_IP=192.168.6.1
sudo apt-get update
sudo apt-get -qq --no-install-recommends install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo apt-get install docker-compose

TOKEN=$(ssh -p 22 "root@node0" "docker swarm join-token --quiet worker")
sudo docker swarm join --token $TOKEN $MANAGER_IP:2377
sudo modprobe mpls_router