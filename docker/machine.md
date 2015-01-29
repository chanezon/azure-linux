# Provisioning Docker containers on Azure with Docker machine

This tutorial is part of [P@'s Linux on Azure series](/../../).

[Docker machine](https://github.com/docker/machine) is a recent Docker project released 12/4/2014. It  makes it really easy to create Docker hosts on local hypervisors and cloud providers. It creates servers, installs Docker on them, then configures the Docker client to talk to them. There is an Azure driver for it.

## Install machine

Download one of the [Docker machine preview builds](https://github.com/docker/machine/releases) and move ot somewhere in your PATH. Alternatively you can build it (see  intsructions at the end)

## Create a VM

```
$ machine create -d azure \
--azure-subscription-id="9b5910a1-...-8e79d5ea2841" \
--azure-subscription-cert="azure-cert.pem" \
pat-1

INFO[0000] Creating Azure machine...                    
INFO[0052] Waiting for SSH...                           
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  6715  100  6715    0     0  19104      0 --:--:-- --:--:-- --:--:-- 19076
modprobe: FATAL: Module aufs not found.
+ sudo -E sh -c sleep 3; apt-get update
+ sudo -E sh -c sleep 3; apt-get install -y -q linux-image-extra-3.13.0-36-generic
E: Unable to correct problems, you have held broken packages.
modprobe: FATAL: Module aufs not found.
Warning: tried to install linux-image-extra-3.13.0-36-generic (for AUFS)
 but we still have no AUFS.  Docker may not work. Proceeding anyways!
+ sleep 10
+ [ https://get.docker.com/ = https://get.docker.com/ ]
+ sudo -E sh -c apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
gpg: requesting key A88D21E9 from hkp server keyserver.ubuntu.com
gpg: key A88D21E9: public key "Docker Release Tool (releasedocker) <docker@dotcloud.com>" imported
gpg: Total number processed: 1
gpg:               imported: 1  (RSA: 1)
+ sudo -E sh -c echo deb https://get.docker.com/ubuntu docker main > /etc/apt/sources.list.d/docker.list
+ sudo -E sh -c sleep 3; apt-get update; apt-get install -y -q lxc-docker
+ sudo -E sh -c docker version
INFO[0341] "pat-1" has been created and is now the active machine 
INFO[0341] To connect: docker $(machine config pat-1) ps 
```

There is an option --azure-name to specify the name you want Azure to use for the cloud service where this machine will be created, but it does not seem to be taken into account. I logged an issue about this https://github.com/docker/machine/issues/419

machine writes metadata about the machine that has been created at ~/.docker/machines/[machine-name]/config.json, and creates certificates to secure communication with the remote machine in ~/.docker/machines/[machine-name]

```
ls ~/.docker/machines/pat-1
azure_cert.pem	cert.pem	id_rsa		key.pem		server-key.pem
ca.pem		config.json	id_rsa.pub	private.pem	server.pem

cat ~/.docker/machines/pat-1/config.json 
{"DriverName":"azure","Driver":{"MachineName":"pat-1-20150128000516","SubscriptionID":"9b5910a1-d954-4b45-85e8-8e79d5ea2841","SubscriptionCert":"/Users/pat/.azure/9b5910a1-d954-4b45-85e8-8e79d5ea2841.pem","PublishSettingsFilePath":"","Name":"","Location":"West US","Size":"Small","UserName":"ubuntu","UserPassword":"","Image":"b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-14_04_1-LTS-amd64-server-20140927-en-us-30GB","SSHPort":22,"DockerPort":2376,"CaCertPath":"","PrivateKeyPath":""},"CaCertPath":"","ServerCertPath":"","ServerKeyPath":"","PrivateKeyPath":"","ClientCertPath":""}
```

One word of caution: MachineName is the name of the cloud service that will be created in Azure. A cloud service name must be between 3 and 25 characters. machine adds a 16 character timestamp postfix to the name you provide on the command line. This means you want to use a machine name that is shorter than 9 characters. Else machine will throw an error message.

The Azure driver has many other options: according to machine create --help
```
   --azure-docker-port '2376'							Azure Docker port
   --azure-image 								Azure image name. Default is Ubuntu 14.04 LTS x64 [$AZURE_IMAGE]
   --azure-location 'West US'							Azure location [$AZURE_LOCATION]
   --azure-name 								Azure cloud service name
   --azure-password 								Azure user password
   --azure-publish-settings-file 						Azure publish settings file [$AZURE_PUBLISH_SETTINGS_FILE]
   --azure-size 'Small'								Azure size [$AZURE_SIZE]
   --azure-ssh-port '22'							Azure SSH port
   --azure-subscription-cert 							Azure subscription cert [$AZURE_SUBSCRIPTION_CERT]
   --azure-subscription-id 							Azure subscription ID [$AZURE_SUBSCRIPTION_ID]
   --azure-username 'ubuntu'							Azure username
```

## Check the VM

```
$ machine ls
NAME           ACTIVE   DRIVER   STATE     URL
pat-1                   azure    Running   tcp://pat-1-20150128000516.cloudapp.net:2376
pat-2          *        azure    Running   tcp://pat-2-20150128000710.cloudapp.net:2376
```

## Have fun with Docker

```
docker $(machine config pat-1) ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES

docker $(machine config pat-1) run -t -i ubuntu /bin/bash
Unable to find image 'ubuntu' locally
ubuntu:latest: The image you are pulling has been verified
511136ea3c5a: Pull complete 
53f858aaaf03: Extracting [==================================================>] 197.2 MB/197.2 MB
53f858aaaf03: Pull complete 
837339b91538: Pull complete 
615c102e2290: Pull complete 
b39b81afc8ca: Pull complete 
Status: Downloaded newer image for ubuntu:latest
root@6aafed0df747:/# 
```

With just 3 arguments, docker machine allows you to start launching docker containers in Azure in less than 5 minutes.

## (Optional) Build machine yourself

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

Have fun with Docker machine!
