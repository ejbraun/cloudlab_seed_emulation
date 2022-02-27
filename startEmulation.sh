
#1. extract swarm token from manager node
#2. start up worker nodes (passing in token + ip address as env vars)
#3. once number of nodes in swarm == number of nodes expected
#3a. create docker registry
    # docker service create --name registry --publish published=5000,target=5000 registry:2
#3b. iterate through folders in priority.txt and do
    # docker-compose -f ./containers/{folder_name}/docker-compose.yml build
    # docker-compose -f ./containers/{folder_name}/docker-compose.yml push
    # docker stack deploy --compose-file ./containers/{folder_name}/docker-compose.yml {folder_name}