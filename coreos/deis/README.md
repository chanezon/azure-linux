# Installing Deis on a CoreOS cluster on Azure

This tutorial is part of [P@'s Linux on Azure series](/../../).

[Deis](http://deis.io/overview/) is "an open source PaaS that makes it easy to deploy and manage applications on your own servers. Deis builds upon Docker and CoreOS to provide a lightweight PaaS with a Heroku-inspired workflow".

This tutorial explains how to install Deis on Azure, expanding on the [Installing a CoreOS cluster on Azure](/coreos/cloud-init/README.md) tutorial. I won't repeat everything that is already in the in CoreOS tutorial, just explain the Deis specific bits.

## Provision a CoreOS cluster

[Get Deis](http://deis.io/get-deis/) docs has detailed instructions for how to deploy Deis on several clouds, but not for Azure yet. The process is quite similar as the regular deployment of a CoreOS cluster on Azure, with 3 differences: VM sizes, cloud-init config file, IP addresses.

You may want to provision your cluster in one shot using the [Azure CoreOS cluster deployment tool](https://github.com/chanezon/azure-linux/blob/master/coreos/cluster/README.md). For Deis, you will use the --pip --custom-data options.

```
./azure-coreos-cluster pat-coreos-cloud-service \
--ssh-cert ~/.ssh/cert-with-ssh-public-key.cer \
--subscription 9b5910a1-8e79d5ea2841 \
--azure-cert ~/.azure/9b5910a1-8e79d5ea2841.pem \
--ssh-thumb 44EF1BA225BE64154F7A55826CE56EA398C365B5 \
--blob-container-url https://patcoreos.blob.core.windows.net/vhds/ \
--pip \
--custom-data deis-cloud-init.yml
```

### VM Size

[Deis system requirements docs](http://docs.deis.io/en/latest/installing_deis/system-requirements/) recommends 4Gb of RAM and 40Gb disk space for VMs. This means you may want to use an A2/Medium size VM for your deployment (see [Azure VM sizes](http://msdn.microsoft.com/en-us/library/azure/dn197896.aspx)), instead of a Small. That said, for testing it, I successfully deployed my cluster on a Small, but it was very slow. In terms of number of machines, deis recommends 3, 5 or more. The one I created with 3 machines worked, but you may want to extend it to 5 for real apps.

### cloud-init

When creating your VMs, you want to use the [special cloud-init file provided by deis](https://github.com/deis/deis/blob/master/contrib/coreos/user-data.example). They pre-install a bunch of stuff in there, and install will fail without that. Don't forget to get a [new discovery token](https://discovery.etcd.io/new) for your cluster and add that to the file before deploying.

### Instance level public IP addresses

Deis provides its own routing service, and is tied to dns configuration for a domain you own. This means you will need to configure your dns to leverage fixed IP addresses for these VMs. Azure recently introduced a [preview for Instance level public IP addresses](http://msdn.microsoft.com/en-us/library/azure/dn690118.aspx), we'll use that. It's configurable only through Powershell or the new Portal right now. I'll use the portal.
Once your VMs are provisioned, navigate to the portal, get to the IP Addresses box, and set the Instance IP toggle to On. After a few seconds, your Instance IP will appear, copy it in a text file. repeat and rinse for each VM. One limitation during the preview is that you can only assign 5 instance level public IPs per subscription.

<img src="/../../blob/master/img/portal-instance-ip-before.png"/>

<img src="/../../blob/master/img/portal-instance-ip-after.png"/>

At this stage, you should have a CoreOS cluster up and running, test it with fleetctl.

## DNS setup

[Deis requires you own a domain and configure DNS record](http://docs.deis.io/en/latest/managing_deis/configure-dns/#configure-dns):

```
Deis requires one wildcard DNS record. Assuming myapps.com is the top-level domain apps will live under:
*.myapps.com should have A-record entries for each of the load balancer IP addresses
Apps can then be accessed by browsers at appname.myapps.com, and the controller will be available to the Deis client at deis.myapps.com.
```

Use the Instance IP addresses for each machine you configured in the cluster in the previous step, and create a DNS record in your favorite DNS provider. I use [Gandi](http://www.gandi.net/) for my domains, here's what the record looks like for the domain chabas.name:

```
@ 10800 IN A 104.40.87.57
@ 10800 IN A 104.40.88.70
@ 10800 IN A 104.40.88.75
* 10800 IN CNAME @
```

After you submit, this information takes a while to propagate through the dns system. ping your domain name at regular intervals to determine when you can start the next step. The deis controller will be hosted at deis.yourdomain.com. At some point I could ping successfully some urls in that domain from the client but not this one. I solved that by forcing a mapping of deis.yourdomain.com to one of these ip addresses in /etc/hosts.

## Install deisctl

Install deisctl on the client you are using to manage your clsuter. In my case, I've installed it on my Mac laptop.
See [deis docs to install deisctl on your platform](http://docs.deis.io/en/latest/installing_deis/install-deisctl/). At the time of this tutorial, I have used deisctl 1.0.1. Then expose your private key in current session, and set ```DEISCTL_TUNNEL```. I have set ```DEISCTL_TUNNEL``` to the same value as ```FLEET_TUNNEL``` in previous tutorial, using the Azure endpoint name and port for ssh. Deis works like Fleet for authentication, it is using your private key to ssh to the machine.
```shell
ssh-add ~/.ssh/my_private_key.key
export DEISCTL_TUNNEL=pat-spring-doge-2.cloudapp.net:22001
```

Then let deis know about your private key, and set the domain for the cluster.
```
deisctl config platform set sshPrivateKey=~/.ssh/my_private_key.key
deisctl config platform set domain=yourdomain.com
deisctl install platform
```

This will install the platform. The installer deploys fleet units for each of the services that compose the platform. This takes a while.

Then, start the platform.

```
deisctl start platform
```

This takes an even longer while.

```
● ▴ ■
■ ● ▴ Starting Deis...
▴ ■ ●

Storage subsystem...
deis-store-monitor.service: activating/start-pre                                 
deis-store-monitor.service: active/running                                 
deis-store-daemon.service: activating/start-pre                                 
deis-store-daemon.service: active/running                                 
deis-store-metadata.service: activating/start-pre                                 
deis-store-metadata.service: active/running                                 
deis-store-gateway.service: activating/start-pre                                 
deis-store-gateway.service: active/running                                 
deis-store-volume.service: activating/start-pre                                 
deis-store-volume.service: deactivating/final-sigterm                                 
deis-store-volume.service: activating/auto-restart                                 
deis-store-volume.service: activating/start-pre                                 
deis-store-volume.service: active/running                                 
Logging subsystem...
deis-logger.service: activating/start-pre                                 
deis-logger.service: active/running                                 
deis-logspout.service: activating/start-pre                                 
deis-logspout.service: active/running                                 
Control plane...
deis-controller.service: activating/start-pre                                 
deis-cache.service: activating/start-pre                                 
deis-database.service: activating/start-pre                                 
deis-registry.service: activating/start-pre                                 
deis-cache.service: active/running                                 
deis-registry.service: active/running                               
deis-controller.service: active/running
```

You can check progress in another terminal window using:
```
deisctl list
```

That process didn't work well for me the first time, some units would not start. Here are a few commands I found useful to understand what happens. Sshing to the box and using journalctl also helped. [Deis troubleshooting guide](http://docs.deis.io/en/latest/troubleshooting_deis/#other-issues
) is a bit empty for now, but I expect it to grow as the platform gets more popular and classic failure modes get more documented.

```
deisctl uninstall platform && deisctl install platform && deisctl start platform
deisctl list
etcdctl ls / --recursive
deisctl restart store-daemon
deisctl journal builder
etcdctl get /deis/platform/domain
eisctl status controller
● deis-controller.service - deis-controller
   Loaded: loaded (/run/fleet/units/deis-controller.service; linked-runtime)
   Active: active (running) since Thu 2014-11-20 05:23:42 UTC; 1h 36min ago
 Main PID: 2398 (sh)
   CGroup: /system.slice/deis-controller.service
           ├─2398 /bin/sh -c IMAGE=`/run/deis/bin/get_image /deis/controller` && docker run --name deis-controller --rm -p 8000:8000 -e EXTERNAL_PORT=8000 -e HOST=$COREOS_PRIVATE_IPV4 -v /var/run/fleet.sock:/var/run/fleet.sock -v /var/lib/deis/store:/data $IMAGE
           └─2416 docker run --name deis-controller --rm -p 8000:8000 -e EXTERNAL_PORT=8000 -e HOST=192.168.0.6 -v /var/run/fleet.sock:/var/run/fleet.sock -v /var/lib/deis/store:/data deis/controller:v1.0.1

Nov 20 06:27:24 pat-spring-doge-2-3 sh[2398]: INFO vanity-yodeling: pat scaled containers web=1
Nov 20 06:37:05 pat-spring-doge-2-3 sh[2398]: INFO spring-doge: pat scaled containers cmd=1
```

Once deisctl list lets you know that all units have started correctly, it should look like that:

```
deisctl list
UNIT				MACHINE			LOAD	ACTIVE	SUB
deis-builder.service		4830c4b8.../192.168.0.5	loaded	active	running
deis-cache.service		d00a6b6f.../192.168.0.4	loaded	active	running
deis-controller.service		701e7304.../192.168.0.6	loaded	active	running
deis-database.service		d00a6b6f.../192.168.0.4	loaded	active	running
deis-logger.service		701e7304.../192.168.0.6	loaded	active	running
deis-logspout.service		4830c4b8.../192.168.0.5	loaded	active	running
deis-logspout.service		701e7304.../192.168.0.6	loaded	active	running
deis-logspout.service		d00a6b6f.../192.168.0.4	loaded	active	running
deis-publisher.service		4830c4b8.../192.168.0.5	loaded	active	running
deis-publisher.service		701e7304.../192.168.0.6	loaded	active	running
deis-publisher.service		d00a6b6f.../192.168.0.4	loaded	active	running
deis-registry.service		4830c4b8.../192.168.0.5	loaded	active	running
deis-router@1.service		d00a6b6f.../192.168.0.4	loaded	active	running
deis-router@2.service		701e7304.../192.168.0.6	loaded	active	running
deis-router@3.service		4830c4b8.../192.168.0.5	loaded	active	running
deis-store-daemon.service	4830c4b8.../192.168.0.5	loaded	active	running
deis-store-daemon.service	701e7304.../192.168.0.6	loaded	active	running
deis-store-daemon.service	d00a6b6f.../192.168.0.4	loaded	active	running
deis-store-gateway.service	4830c4b8.../192.168.0.5	loaded	active	running
deis-store-metadata.service	4830c4b8.../192.168.0.5	loaded	active	running
deis-store-metadata.service	701e7304.../192.168.0.6	loaded	active	running
deis-store-metadata.service	d00a6b6f.../192.168.0.4	loaded	active	running
deis-store-monitor.service	4830c4b8.../192.168.0.5	loaded	active	running
deis-store-monitor.service	701e7304.../192.168.0.6	loaded	active	running
deis-store-monitor.service	d00a6b6f.../192.168.0.4	loaded	active	running
deis-store-volume.service	4830c4b8.../192.168.0.5	loaded	active	running
deis-store-volume.service	701e7304.../192.168.0.6	loaded	active	running
deis-store-volume.service	d00a6b6f.../192.168.0.4	loaded	active	running
```

## Install the deis client

Install the deis client according to the [deis documentation](http://docs.deis.io/en/latest/using_deis/install-client/#install-the-deis-client).

## Register a user

The controller runs at deis.yourdomain.com. You need to register a user there. The first user will have admin access.
```
deis register http://deis.yourdomain.com
username: myuser
password:
password (confirm):
email: myuser@example.com
Registered myuser
Logged in as myuser
```

If you see that the controller has started, but that the client can't connect to it, check that you can ping it and that it pings the right ip address. It may be a dns issue as explained above.

Deis has 3 modes to deploy apps: Buildpacks with git, Dockerfiles, Docker images. If you plan to use git, upload your ssh public key for git use.


```
deis keys:add
```

## Create and manage apps

The [deis client command reference](http://docs.deis.io/en/latest/reference/client/) is handy in the beginning. Useful commands are:

```
deis apps:list
deis apps:info -a myapp
deis apps:logs -a myapp
deis apps:info -a spring-doge
=== spring-doge Application
{
  "updated": "2014-11-20T06:26:56UTC", 
  "uuid": "ebd7a31d-7bc2-466e-a05e-9033bccf51cb", 
  "created": "2014-11-20T06:26:56UTC", 
  "url": "spring-doge.chabas.name", 
  "owner": "pat", 
  "id": "spring-doge", 
  "structure": {}
}

=== spring-doge Processes

--- cmd: 
cmd.1 created (v2)
cmd.1 created (v3)
```

One thing to note: deis seems to look at the current directory you are in to determine which app you are working on. If you want to target a specific app, add -a myapp option at the end of the command.

You can create apps using Buildpacks with git, Dockerfiles, Docker images. See [Deis Deploy an Application docs](http://docs.deis.io/en/latest/using_deis/deploy-application/) for detailed instructions.

A few things to note:
* in my test, using the Mac client, commands to create apps never end. You have to check status of the deployment using deis apps:info and apps:logs, then Ctrl-C the command. Not sure if it's a bug or if I configured something wrong.
* for Docker image deployment, you typically need to set environment variables. You cannot do this in one shot: first you create the app with deis apps:create, then you set env variables with deis config:set.
* scale your apps with deis scale [web|cmd]=n. The type of process you want to scale depends on the type of app: web for buildpacks, cmd for Dockerfiles.

Example creating an app based on a Dockerfile (see [Installing a CoreOS cluster on Azure](/coreos/cloud-init/README.md) tutorial for details about the app and the Docker image):

```
mkdir spring-doge && cd spring-doge
deis create
deis pull chanezon/spring-doge
deis config:set MONGODB_URI=mongodb://username:password@hotname:port/dbname
deis scale cmd=3
deis apps:open
```

## Conclusion

Have fun with Deis on Azure. The orchestration platform still feels a bit rough around the edge, with a few bugs, lacks of functionalities and sparse documentation, but it seems to be in active development, and while the setup takes some time, the developer workflow is very nice.
