#!/bin/bash

# Create a virtual system(VM)
multipass launch -d 10G --name master

# Update list of packages on instance
multipass exec master sudo apt update

# Install docker on instance and init docker swarm
multipass exec master sudo apt install docker.io
multipass exec master sudo docker swarm init --advertise-addr 192.168.99.112

# Creating new machines to serve as node
multipass launch -d 10G --name node1
multipass launch -d 10G --name node2

# Retrieve command with token
# multipass exec master sudo docker swarm join-token worker  

# Adding new machinas like a worker to swarm
multipass exec node1 sudo apt update
multipass exec node1 sudo apt install docker.io
multipass exec node1 docker swarm join --token <token> 192.168.99.112:2377
multipass exec node2 sudo apt update
multipass exec node2 sudo apt install docker.io
multipass exec node2 docker swarm join --token <token> 192.168.99.112:2377

# Going up a service
multipass copy-files $(pwd)/app-exemplo master:/home
multipass exec master docker build -t node .
multipass exec master docker service create -p 8080:3000 -d node 

# To test application, access: 192.168.99.112:8080

# Get ip to node
# multipass exec node1 docker node inspect --format '{{range .Status}}{{.Addr}}{{end}}'
# multipass exec node2 docker node inspect --format '{{range .Status}}{{.Addr}}{{end}}'

# Backup swarm
multipass exec master sudo cp -r /var/lib/docker/swarm backup

# Restore backup
multipass exec master sudo cp -r backup/* /var/lib/docker/swarm
multipass exec master sudo docker swarm init --force-new-cluster --advertise-addr 192.168.99.112

# Adding redundancy with another manager
multipass exec master sudo docker swarm join-token manager
multipass exec node1 docker swarm join --token <token> 192.168.99.112:2377
multipass exec node2 docker swarm join --token <token> 192.168.99.112:2377
multipass launch -d 10G --name node3
multipass launch -d 10G --name node4
multipass exec master sudo docker swarm join-token worker
multipass exec node3 docker swarm join --token <token> 192.168.99.112:2377
multipass exec node4 docker swarm join --token <token> 192.168.99.112:2377

# Remove manager
multipass exec node1 docker node remote master
multipass exec node1 docker node rm master

# Re-adds manager master 
multipass exec node1 sudo docker swarm join-token manager
multipass exec master docker swarm join --token <token> 192.168.99.112:2377 --advertise-addr 192.168.99.112


# Remove a node from te worker
# multipass exec node2 docker swarm leave
# multipass exec master rm $(multipass exec node2 docker swarm ls -a)

# Delete VMs in multipass
# multipass recover master node1 node2 node3 node4
# multipass delete master node1 node2 node3 node4
# multipass purge
