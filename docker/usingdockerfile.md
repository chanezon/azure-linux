# Using the chanezon/azure-linux Dockerfile

I'm writing these tutorials on a Mac. They make use of many tools that are easy to install on Mac or Linux, but less so on Windows: docker, python, pip, Azure Python SDK, Azure Cross platform CLI, docker machine,...

If you use these tutorials, there is a good chance that you have at least a Docker client installed on your machine. In order to make your life easier, this project has a [Dockerfile](Dockerfile) that has all these tools and their dependencies installed.

I have built it as [chanezon/azure-linux](https://registry.hub.docker.com/u/chanezon/azure-linux/) on docker hub.

It may not be up to date, since I haven't setup continuous integration yet.

One way of running the container is to provision an [Ubuntu Docker VM from the Azure marketplace in the Azure portal](http://azure.microsoft.com/blog/2015/01/08/introducing-docker-in-microsoft-azure-marketplace/), then ssh to it, and run the container from there.

```
docker run -ti chanezon/azure-linux
```

You are then root in /usr/src/app, where this project is checked out. You can follow the tutorial from there.

If you run this container from your personal machine, or have ssh or azure certs on the machine from which you run the container, you can also mount data volumes, and run the container as a command.

chanezon/azure-linux defines 2 volumes: /usr/data where you can mount the host directory where your azure certifcates are, and /root/.docker where you can mount a host directory where docker machine metadata will be persisted among several container runs. These 2 volumes allow you to use chanezon/azure-linux as a command, instead of opening a terminal in the container to do work.

This is an example of running docker machine from the container, mounting your ~/.ssh directory where your azure cert is, as well as mounting a local directory ~/.dockerindocker where machine is going to store your machine meta data, so that you can leverage them in future launches of the container.
```
docker run -v ~/.ssh:/usr/data -v ~/.dockerindocker:/root/.docker chanezon/azure-linux machine create -d azure --azure-subscription-id="9b5910a1...-8e79d5ea2841" --azure-subscription-cert="/usr/data/azure-cert.pem" pat
```

docker is installed in the container, so after this you can connect to your newly created docker host with:
```
MACHINE=$(docker run -v ~/.ssh:/usr/data -v ~/.dockerindocker:/root/.docker chanezon/azure-linux machine config pat)
docker run -v ~/.ssh:/usr/data -v ~/.dockerindocker:/root/.docker chanezon/azure-linux docker $MACHINE ps
```

One file you will need for a lot of this work is your Azure management certificate. See [Azure CoreOS cluster deployment tool](/coreos/cluster/README.md) for how to generate it. If you generate it on another machine, you can either mount the directory where it is, if running on the same machine, or create it in the container with vi or cat, pasting from your client machine.
