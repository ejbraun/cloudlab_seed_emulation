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

sudo docker swarm init --advertise-addr=$MANAGER_IP

sudo modprobe mpls_router

while [[ $(sudo docker node ls | awk 'END{print NR}') != $1 ]];
do
    echo "waiting for all worker nodes to join swarm..."
    sleep 10
done
# Create docker registry
sudo docker service create --name registry --publish published=5000,target=5000 registry:2
# Start up services
filename='containers/priority.txt'
while read p; do
    sudo docker-compose -f "containers/${p}/docker-compose.yml" build
    sudo docker-compose -f "containers/${p}/docker-compose.yml" push
    sudo docker service create \
       --name "${p}-wrapper" \
       --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
       --mount type=bind,source="/local/repository/containers/${p}",target=/tmp/ \
       --workdir /tmp/ \
       docker/compose \
       docker-compose up
    echo "Deployed $p to swarm"
done < "$filename"
