while [[ $(docker node ls | awk 'END{print NR}') != $1 ]];
do
    sleep 10
    echo "waiting for all worker nodes to join swarm..."
done
# Create docker registry
docker service create --name registry --publish published=5000,target=5000 registry:2
# Start up services
filename='priority.txt'
while read p; do
    docker-compose -f "containers/${p}/docker-compose.yml" build
    docker-compose -f "containers/${p}/docker-compose.yml" push
    docker stack deploy --compose-file "containers/$p/docker-compose.yml" "${p}"
    echo "Deployed $p to swarm"
    sleep 10
done < "$filename"
