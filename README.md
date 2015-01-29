# P@'s Linux on Azure tutorials

<img src="/img/Microsoft-Loves-Linux.png"/>

Documentation and examples for how to leverage various linux technologies with Microsoft Azure.

I write tutorials with a bit of automation code about things I didn't see documented elsewhere, or where I want to add context and details to existing docs and blog posts. I also list a set of links to relevant docs or blog posts that I found useful.

## Using the Dockerfile

I'm writing these tutorials on a Mac. They make use of many tools that are easy to install on Mac or Linux, but less so on Wndows: docker, python, pip, Azure Python SDK, Azure Cross platform CLI, docker machine,...

If you use these tutorials, there is a good chance that you have at least a Docker client installed on your machine. In order to make your life easier, this project has a [Dockerfile](Dockerfile) that has all these tools and their dependencies installed.

I have built it as [chanezon/azure-linux](https://registry.hub.docker.com/u/chanezon/azure-linux/) on docker hub.

It may not be up to date, since I haven't setup continuous integration yet.

One way of running the container is to provision an [Ubuntu Docker VM from the Azure marketplace in the Azure portal](http://azure.microsoft.com/blog/2015/01/08/introducing-docker-in-microsoft-azure-marketplace/), then ssh to it, and run the container from there.

```
docker run -ti chanezon/linux
```

You are then root in /usr/src/app, where this project is checked out. You can follow the tutorial from there.

If you run this container from your personal machine, or have ssh or azure certs on the machine from which you run the container, you can also mount data volumes, and run the container as a command.

This is an example of running docker machine from the container, mounting your ~/.ssh directory where your azure cert is, as well as mounting a local directory ~/.dockerindocker where machine is going to store your machine meta data, so that you can leverage them in future launches of the container.
```
docker run -v ~/.ssh:/usr/data -v ~/.dockerindocker:/root/.docker chanezon/azure-linux machine create -d azure --azure-subscription-id="9b5910a1...-8e79d5ea2841" --azure-subscription-cert="/usr/data/azure-cert.pem" pat
```

docker is installed in the container, so after this you can connect to your newly created docker host with:
```
MACHINE=$(docker run -v ~/.ssh:/usr/data -v ~/.dockerindocker:/root/.docker chanezon/azure-linux machine config pat-22)
docker run -v ~/.ssh:/usr/data -v ~/.dockerindocker:/root/.docker chanezon/azure-linux docker $MACHINE ps
```

One file you will need for a lot of this work is your Azure management certificate. See [Azure CoreOS cluster deployment tool](/coreos/cluster/README.md) for how to generate it. If you generate it on another machine, you can either mount the directory where it is, if running on the same machine, or create it in the container with vi or cat, pasting from your client machine.

## CoreOS

### Tutorials

* [Installing a CoreOS cluster on Azure](/coreos/cloud-init/README.md) Docker orchestration with Fleet. Deploying a Java 8 application using Spring Boot and MongoDB on a CoreOS cluster on Azure, using Docker and Fleet. Deploying @NetflixOSS containers. This tutorial explains how to manually deploy VMs in your cluster. For a more automated process, see the cluster deployment tool tutorial below.
* [Azure CoreOS cluster deployment tool](/coreos/cluster/README.md) Python script to deploy a CoreOS cluster in one shot.
* [Installing Weave Docker virtual network on CoreOS on Azure](/coreos/weave/README.md). Weave allows you to manage networking for your Docker containers from the command line. It includes a dns service.
* [Installing Deis on a CoreOS cluster on Azure](/coreos/deis/README.md) Docker orchestration with Deis. Fun and games with DNS settings, then deploy a ruby app with git, and a Docker image for a Java 8 app.
* [Installing Kubernetes on a CoreOS cluster on Azure](/coreos/kubernetes/README.md) (Work in Progress), Docker orchestration with Kubernetes. Cf links below for 2 approaches to networking that need testing on Azure: Weave and Flannel.

### Interesting links

The main issue installing Kubernetes on Azure is networking: [Kubernetes needs to assign 1 IP address per pod](https://github.com/GoogleCloudPlatform/kubernetes/blob/master/docs/design/networking.md), which works fine on Google Cloud Platform, where [advanced routing](https://cloud.google.com/compute/docs/networking#routing) allows you to configure your VMs so that each get assigned a /24 address space. On Azure today, you need to leverage some kind of overlay network to accomplish that. There are different approaches in how to do this:

* [Kubernetes, Getting started on Microsoft Azure](https://github.com/GoogleCloudPlatform/kubernetes/blob/master/docs/getting-started-guides/azure.md) uses Ubuntu images, OpenVPN for networking.
* [Weave for Kubernetes on CoreOS](http://weaveblog.com/2014/11/11/weave-for-kubernetes/) seems promising, and should be a good approach for Azure
* [Deploying Kubernetes on CoreOS with Fleet and Flannel](https://github.com/kelseyhightower/kubernetes-fleet-tutorial/blob/master/README.md) the other main approach

## Ubuntu Core

[Snappy Ubuntu Core](http://www.ubuntu.com/cloud/tools/snappy) is a minimal server image of Ubuntu, coupled with a transactional OS update mechanism, similar to CoreOS, and an application model inspired by mobile app stores called snappy. It was announced 12/9/2014, with initial support for Azure first.

* [Getting started with Snappy Ubuntu Core on Azure](/ubuntu/README.md)

## Docker

### Tutorials

* [Provisioning Docker containers on Azure with Docker machine](/docker/machine.md)

### Interesting links

I assume you already know Docker basics: there are plenty of resources and tutorials out there about it. If you don't, get started with @kartar's excellent book [The Docker book - Containerization is the new virtualization](http://www.dockerbook.com/), then read the official docs.

Here are resources to understand how Docker works internally, where it is going, and what kind of innovation is happening in different part of the ecosystem as it matures: orchestration, networking, storage, management and monitoring.

* Azure Docs [Using the Docker VM Extension from Azure Cross-Platform Interface (xplat-cli)](http://azure.microsoft.com/en-us/documentation/articles/virtual-machines-docker-with-xplat-cli/)
* [Creating containers](http://crosbymichael.com/creating-containers-part-1.html) @crosbymichael's series on the internals of what containers are is a very good read, to understand how Docker works.
* @jpetazzo's [articles](http://blog.docker.com/author/jerome/) and [decks](http://www.slideshare.net/jpetazzo/) also go pretty deep.
* [Using Fig and Flocker to build, test, deploy and migrate multi-server Dockerized apps](https://clusterhq.com/blog/fig-flocker-multi-server-docker-apps/) One area of innovation for Docker is storage. One issue with Docker is that stateless containers are easy to move to a different host (typically done by an orchestration engine), but stateful containers for database services are tied to a host. Flocker is an interesting answer to this issue, allowing you to snapshot and migrate your data volumes using a port of zfs for Linux. Flocker provides multi host container orchestration, supporting part of the fig format (which will be the format supported in Docker groups), but the most differentiating aspect they provide is the zfs based volume migration capability.
*  [Life and Docker networking](http://weaveblog.com/2014/11/13/life-and-docker-networking/) Networking is another big area of innovation in the Docker ecosystem. Thoughtful essay by @monadic about the various approaches to Docker networking these days, and the need for a plugin system for Docker.
* [Docker groups](https://github.com/docker/docker/issues/9175) The Docker stack composition proposal, for Docker native orchestration. There's a release implementing it that you can try. This is the replacement for Fig.
* [Docker clustering with swarm](https://github.com/docker/swarm)
* [Docker plugins proposal](https://github.com/docker/docker/pull/8968)
* [Docker hosts management with machine](https://github.com/docker/machine) there is an Azure driver for it
