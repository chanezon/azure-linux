# Provisioning Docker containers on Azure with Docker machine

This tutorial is part of [P@'s Linux on Azure series](/../../).

[Docker machine](https://github.com/docker/machine) is a new Docker project released 12/4/2014. It  makes it really easy to create Docker hosts on local hypervisors and cloud providers. It creates servers, installs Docker on them, then configures the Docker client to talk to them. There is an Azure driver for it, but the initial release from 12/4/2014 included a bug that prevented it to work with Azure. That [bug was fixed](https://github.com/docker/machine/issues/26) 12/11/2014, but the current build does not include it. These are temporary instructions explaining how to compile machine to provision Azure VMs today. In the future, you will be able to use [Docker machine preview builds out of the box](https://github.com/docker/machine/releases)

## Build machine

Instructions are for Mac OS X. Install Docker (tested with 1.3.2) on your mac. Make sure it works and that boot2docker vm has a share of /Users
Clone machine code and build it. The build uses Docker, and takes a while the first time: one of the images needed is > 1Gb.

```
git clone https://github.com/docker/machine.git
cd machine
script/build
Sending build context to Docker daemon 3.469 MB
Sending build context to Docker daemon 
Step 0 : FROM golang:1.3-cross
golang:1.3-cross: The image you are pulling has been verified
36fd425d7d8a: Pull complete 
36fd425d7d8a: Download complete 
...
Number of parallel builds: 4

-->      darwin/386: github.com/docker/machine
...
-->   windows/amd64: github.com/docker/machine
```

It is using a Docker container to do a cross platform build of Docker. The binaries are generated in the current directory. Create a symlink from somewhere in your PATH to machine_darwin_386.

## Create a VM

```
$ machine create -d azure \
--azure-subscription-id="9b5910a1-...-8e79d5ea2841" \
--azure-subscription-cert="azure-cert.pem" \
--azure-location="West US" \
--azure-name="pat-docker" \
--azure-username="pat" \
pat-docker

INFO[0000] Creating Azure host...                       
INFO[0055] Waiting for SSH...                           
INFO[0155] Waiting for docker daemon on host to be available... 
INFO[0235] "pat-docker" has been created and is now the active machine. To point Docker at this machine, run: export DOCKER_HOST=$(machine url) DOCKER_AUTH=identity 
$ machine ls
NAME         ACTIVE   DRIVER   STATE     URL
pat-docker   *        azure    Running   tcp://pat-docker.cloudapp.net:4243

$ export DOCKER_HOST=$(machine url) DOCKER_AUTH=identity
```

machine creates the certificates in ~/.docker/hosts/<hostname>, and metadata about how the vm was provisioned in ~/.docker/hosts/<hostname>/config.json. It also writes meta data about all the hosts it manages in ~/.docker/known-hosts.json.

## Try it out

Download a [build of Docker with Identity authentication](https://github.com/docker/machine). This build includes an [implementation](https://github.com/docker/docker/pull/8265) of the [proposal Docker Engine Keys for Docker Remote API Authentication and Authorization](https://github.com/docker/docker/issues/7667).
I renamed it docker-id, to avoid conflicts with regular docker.

```
./docker-id run -ti ubuntu /bin/bash
```

Have fun with Docker machine!
