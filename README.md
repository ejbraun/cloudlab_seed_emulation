# BGPChain CloudLab Scenario Generator
    
## Seed Emulator
### Changes Made to Seed Emulator
This section details the changes made to the seed emulator library:

 1. In `seedemu/compiler/Docker.py`, changed `DockerCompilerFileTemplates["compose-service"]` to use image pushed to swarm's local registry. 
 2. In `seedemu/compiler/DistributedDocker.py`, added `attachable:true` to `DistributedDockerCompilerFileTemplates["compose_network_ix_master"]` in order for to be compatible w/ docker-compose v2.
 3. In `seedemu/compiler/DistributedDocker.py`, added logic to generate the `priority.txt` file that is read by the primary manager node in CloudLab.
___
### Scenario Flow
This section details the steps for writing a scenario:
 1. Clone https://github.com/ejbraun/seed-emulator-bgpchain.
 2. Write the scenario you wish to test using the seed emulator libraries. There are many examples present in the `examples` directory.
 3. Make sure to `source development.env` in the root level of the `seed-emulator-bgpchain`.
 4. After rendering the emulation (`emu.render()`), call the following line to compile w/ the correct compiler for the CloudLab profile: `emu.compile(DistributedDocker(), "./containers")`.
 5. Run `python3 <scenario_name>.py` to render and compile the emulation.
 6. Verify that the correct output files are generated and exist in `containers`. 

Once your scenario has been generated, it is time to move to the https://github.com/ejbraun/cloudlab_seed_emulation repository.
## CloudLab 

### Getting A Scenario Running
This section details the steps for taking the output of a generated scenario and getting it running in CloudLab:

1. Clone https://github.com/ejbraun/cloudlab_seed_emulation.
2. You can choose to either push straight to main or work off a branch. Either way, overwrite the existing containers folder w/ the newly generated folder from your recently compiled scenario and commit + push to the chosen branch.
3. Navigate to https://www.cloudlab.us/show-project.php?project=Escra#profiles and select the profile titled `seed-emulation`. 
4. In the column on the left side, click the `Edit` button.
5.  In the `Repository` row, click on the `Update` button. This will prompt CloudLab to fetch the latest branches from the `cloudlab_seed_emulation` repository. 
6. Find your selected branch's row in the bottom of the page and click the `Instantiate` button. 
7. Click `Next` to skip to `2. Parameterize`.
8. Input the number of nodes you wish to utilize for this scenario and click `Next`.
9. Input the experiment's name, project, and cluster. Click `Next`.
10. Input the experiment duration and then click `Finish`.
11. CloudLab will then provision the instances and start running the associated start up scripts on both worker + manager nodes. Once all nodes in the topology turn green, one can then hop onto one of the nodes by right clicking a chosen node and clicking `Shell`.
12. One ssh'ed onto a shell, run `sudo su -` and `cd /local/repository` to get to the working directory of where the repository code is located on the node.
13. You can check the logs of the startup script w/ `cat start.log`.
14. You can check status of swarm w/ `docker node ls`. You can check status of containers that are running *locally* on this given node w/ `docker ps`. Normal docker commands apply (`docker logs, docker network ls, ...`). 
15. In order to check the status of all the services deployed remotely across the swarm, run `docker service ls`. 
___
### CloudLab Experiment Creation + Runtime Explained

### profile.py

Lines 13-136 are all boiler plate code. The most interesting / novel portion of code are Lines 150-156.
        
    if params.nodeCount > 1:
        iface = node.addInterface("eth1")
        iface.addAddress(pg.IPv4Address("192.168.6.{}".format(i + 1), "255.255.255.0"))
        lan.addInterface(iface)
        # Allows worker nodes to ssh into manager nodes to fetch swarm token
        node.installRootKeys(True, True)
        pass
We assign each node in the experiment an ip address. The primary manager node always has `192.168.6.1`. 

We install root keys onto each of the worker nodes in order for them to fetch the swarm token required to join the swarm.
___
The last interesting portion of the code is Lines 181-185.

    #Run service for manager node
    if i == 0:
        node.addService(pg.Execute(shell="bash", command="/local/repository/managerStartUp.sh {} 2>&1 > /local/repository/start.log".format(params.nodeCount + 1)))
    #Run service for worker nodes
    else:
        node.addService(pg.Execute(shell="bash", command="/local/repository/workerStartUp.sh 2>&1 > /local/repository/start.log"))
We run the startup script of `managerStartUp.sh` on the primary manager node and run the startup script of `workerStartUp.sh` on the rest of the nodes.
___
### managerStartUp.sh
This installs docker.

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
___
This installs docker-compose.

    curl -L "https://github.com/docker/compose/releases/download/$(curl https://github.com/docker/compose/releases | grep -m1 '<a href="/docker/compose/releases/download/' | grep -o 'v[0-9:].[0-9].[0-9]')/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
___
Now we initialize the swarm w/ `sudo docker swarm init --advertise-addr=$MANAGER_IP`.

___

At this point of the script, we must wait until all other nodes in the experiment have joined the swarm. profile.py passes number of nodes in cluster as parameter which is what the output of `docker node ls` will be compared against.

    while [[ $(sudo docker node ls | awk 'END{print NR}') != $1 ]];
    do
    echo "waiting for all worker nodes to join swarm..."
    sleep 10
    done
___
We then create the local docker registry that we will use to push our built images so different nodes in the swarm can run no matter where they are located.
`sudo docker service create --name registry --publish published=5000,target=5000 registry:2
`

___
The final portion of the code is what schedules the virtualized AS'es / IX'es on different nodes in the swarm.

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
We read from the generated `priority.txt` inside of the `containers` folder which dictates the order in which we must deploy services. This is important because certain services (like IX'es) have overlay networks that must exist before other services are launched. 

For each service, we build and then push the image to the local docker registry. After this is complete, we then perform a hackish way to deploy these services across different virtual nodes in our swarm.

Once these services are all deployed, the startup script is complete.
___
### workerStartUp.sh

The worker startup script is much simpler than the manager startup script.

Lines 2-18 are identical to the manager startup script.

The final portion of the code is how the non-primary manager node discovers the swarm token and joins the swarm.

    TOKEN=$(sudo ssh -o StrictHostKeyChecking=no -p 22 "root@node0" "docker swarm join-token --quiet manager")
    while [[ $TOKEN != SWMTKN* ]]
    do
        echo "waiting for manager node to create the swarm..."
        sleep 5
        TOKEN=$(sudo ssh -o StrictHostKeyChecking=no -p 22 "root@node0" "docker swarm join-token --quiet manager")
    done
    TOKEN=$(sudo ssh -o StrictHostKeyChecking=no -p 22 "root@node0" "docker swarm join-token --quiet manager")
    sudo docker swarm join --token $TOKEN $MANAGER_IP:2377
The interesting command here is `TOKEN=$(sudo ssh -o StrictHostKeyChecking=no -p 22 "root@node0" "docker swarm join-token --quiet manager")
`
This command ssh's onto the primary manager node and runs the `docker swarm join-token` command which outputs the swarm token on success. We compare the output of this command to the pattern of `SWMTKN*`. If it is not a match, we wait 5 seconds before attempting the same command again. 
Once we successfully retrieve the swarm token, we can exit the loop and join the swarm w/ `sudo docker swarm join --token $TOKEN $MANAGER_IP:2377
`.

After successfully joining the swarm, the non-primary manager node can then have services scheduled on itself and pull down built images from the swarm's local docker registry. 

___
