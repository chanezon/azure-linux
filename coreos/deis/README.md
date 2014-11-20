# Installing Deis on a CoreOS cluster on Azure

This tutorial is part of [P@'s Linux on Azure series](/../../).

[Deis](http://deis.io/overview/) is "an open source PaaS that makes it easy to deploy and manage applications on your own servers. Deis builds upon Docker and CoreOS to provide a lightweight PaaS with a Heroku-inspired workflow".

This tutorial explains how to install Deis on Azure, expanding on the [Installing a CoreOS cluster on Azure](/coreos/cloud-init/README.md) tutorial. I won't repeat everything that is already in the in CoreOS tutorial, just explain the Deis specific bits.

## Provision a CoreOS cluster

[Get Deis](http://deis.io/get-deis/) docs has detailed instructions for how to deploy Deis on several clouds, but not for Azure yet. The process is quite similar as the regular deployment of a CoreOS cluster on Azure, with 3 differences: VM sizes, cloud-init config file, IP addresses.

### VM Size

[Deis system requirements docs](http://docs.deis.io/en/latest/installing_deis/system-requirements/) recommends 4Gb of RAM and 40Gb disk space for VMs. This means you may want to use an A2/Medium size VM for your deployment (see [Azure VM sizes](http://msdn.microsoft.com/en-us/library/azure/dn197896.aspx)), instead of a Small. That said, for testing it, I successfully deployed my cluster on a Small, but it was very slow. In terms of number of machines, deis recommends 3, 5 or more. The one I created with 3 machines worked, but you may want to extend it to 5 for real apps.

### cloud-init

When creating your VMs, you want to use the [special cloud-init file provided by deis](https://github.com/deis/deis/blob/master/contrib/coreos/user-data.example). They pre-install a bunch of stuff in there, and install will fail without that. Don't forget to get a [new discovery token](https://discovery.etcd.io/new) for your cluster and add that to the file before deploying.

### Instance IP addresses

Deis provides its own routing service, and is tied to dns configuration for a domain you own. This means you will need to configure your dns to leverage fixed IP addresses for these VMs. Azure recently introduced a preview for Instance level IP addresses, we'll use that. It's configurable only through Powershell or the new Portal right now. I'll use the portal.
Once your VMs are provisioned, navigate to the portal, get to the IP Addresses box, and set the Instance IP toggle to On. After a few seconds, your Instance IP will appear, copy it in a text file. repeat and rinse for each VM.

<img src="/../../blob/master/img/portal-instance-ip-before.png"/>

<img src="/../../blob/master/img/portal-instance-ip-after.png"/>

At this stage, you should have a CoreOS cluster up and running, test it with fleetctl.

## DNS setup








