# Provisioning a Docker Swarn cluster on Azure

## Using docker-machine

docker-machine is [integrated with Swarm](https://docs.docker.com/machine/#using-docker-machine-with-docker-swarm). Provisioning a Swarm cluster on Azure is just a matter of minutes with docker-machine.

```
docker run swarm create
1ad59233ccba1aaa40be4774e29b474g
docker-machine create -d azure \
--azure-subscription-id="252a4be8-xxx-587d88952573" \
--azure-subscription-cert="/Users/pat/.ssh/docker-azure-cert.pem" \
--azure-location="East US" \
--azure-size=Small \
--azure-username="pat" \
--swarm \
--swarm-master \
--swarm-discovery token://1ad59233ccba1aaa40be4774e29b474g \
pat-swarm-master-0505

docker-machine create -d azure \
--azure-subscription-id="252a4be8-xxx-587d88952573" \
--azure-subscription-cert="/Users/pat/.ssh/docker-azure-cert.pem" \
--azure-location="East US" \
--azure-size=Small \
--azure-username="pat" \
--swarm \
--swarm-discovery token://1ad59233ccba1aaa40be4774e29b474g \
pat-swarm-node-0505-00
```

There's a [bug in docker-machine](https://github.com/docker/swarm/issues/428) that forces you to create the endpoint for Swarm yourself.
```
azure vm endpoint create pat-swarm-master-0505 3376 3376
```

Then your cluster is ready to use!
```
eval "$(docker-machine env --swarm pat-swarm-master-0505)"
docker info
Containers: 5
Strategy: spread
Filters: affinity, health, constraint, port, dependency
Nodes: 2
 pat-swarm-master-0505: pat-swarm-master-0505.cloudapp.net:2376
  └ Containers: 3
  └ Reserved CPUs: 0 / 1
  └ Reserved Memory: 0 B / 1.721 GiB
 pat-swarm-node-0505-00: pat-swarm-node-0505-00.cloudapp.net:2376
  └ Containers: 2
  └ Reserved CPUs: 0 / 1
  └ Reserved Memory: 0 B / 1.721 GiB

docker run --rm swarm list token://1ad59233ccba1aaa40be4774e29b474g
```

## Customizing your Swarm nodes

If you want to use Swarm filters, you may want to start Docker daemon on certain nodes of your Swarm cluster with labels. In order to do so, ssh to the node, and edit /etc/default/docker to add the lables you need. In this example I mark a machine as being backed by an ssd drive.
```
docker-machine ssh pat-swarm-node-0505-00
sudo vi /etc/default/docker
export DOCKER_OPTS="--tlsverify --tlscacert=/etc/docker/ca.pem --tlskey=/etc/docker/server-key.pem --tlscert=/etc/docker/server.pem --label=provider=azure --host=unix:///var/run/docker.sock --host=tcp://0.0.0.0:2376 --label=storage=ssd"
sudo service docker restart
```
Then I can schedule tasks on my cluster targeting a ssd backend:
```
docker run -d -P -e constraint:storage==ssd --name db mongo
```

## Using ARM templates

ARM templates allow you to deploy clusters on Azure easily. I haven't found a good Swarm ARM template. I guess I need to write one:-)

TBD
