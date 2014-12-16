# Getting started with Snappy Ubuntu Core on Azure

This tutorial is part of [P@'s Linux on Azure series](/../../).

[Snappy Ubuntu Core](http://www.ubuntu.com/cloud/tools/snappy) is a minimal server image of Ubuntu, coupled with a transactional OS update mechanism, similar to CoreOS, and an application model inspired by mobile app stores called snappy. It was announced 12/9/2014, with initial support for Azure first.

The [Ubuntu Core on Azure documentation](http://www.ubuntu.com/cloud/tools/snappy#snappy-azure) provides basic instructions to get started on Azure. This guide adds a few caveats and details, and explains how to get started developing snappy apps using Ubuntu on Azure. We will deploy and update a sample xkcd image server.

<img src="/img/snappy-xkcd-updated.png"/>


## Azure Management Certificate

See Azure documentation for how to setup [Azure Cross Platform CLI](http://azure.microsoft.com/en-us/documentation/articles/xplat-cli/) and connect it to your Azure subscription. See [Azure Management & SSH Certs](/../../blob/master/coreos/cluster/README.md#certs) for a quick version of how to generate these.

## Create the Ubuntu Core VM

To determine the image you can use.
```
azure vm image list|grep Ubuntu-core
data:    b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-core-devel-amd64-20141209-90-en-us-30GB                                      Public    Linux  
data:    b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-core-devel-amd64-20141211-90-en-us-30GB                                      Public    Linux  
```

I have used b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-core-devel-amd64-20141209-90-en-us-30GB for testing.

SSH is disabled by default on Ubuntu Core. Passing the following cloud-config file at VM creation time will enable it. Create a file called cloud.cfg.

```
#cloud-config
snappy:
    ssh_enabled: True
```

One area where the documentation is not super clear right now is username: you need to pass ubuntu as the username. If you pass any other name, the user is not created and you cannot login to the VM. See [Azure documentation for how to generate ssh certificates](http://azure.microsoft.com/en-us/documentation/articles/virtual-machines-linux-use-ssh-key/), or my quicker version [Azure Management & SSH Certs](/../../blob/master/coreos/cluster/README.md#certs).

```
azure vm create pat-snappy \
b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-core-devel-amd64-20141209-90-en-us-30GB \
ubuntu \
--location "West US" \
--ssh \
--no-ssh-password \
--ssh-cert ~/.ssh/ssh-public-key.pem \
--custom-data cloud.cfg
```

## Login and play with snappy apps

SSH to the machine and follow [A snappy tour of Ubuntu Core!](http://www.ubuntu.com/cloud/tools/snappy#core-tour).

## Build your own snappy apps

Once you've tried that, you may want to [build you own snappy apps for Ubuntu Core](http://www.ubuntu.com/cloud/tools/snappy#snappy-apps). The tools to build snappy apps run on Ubuntu Desktop. If you don't have an Ubuntu VM handy, or don't run Ubuntu Desktop, it's easy to provision one in Azure:

```
azure vm create pat-ubuntu \
b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-14_10-amd64-server-20141204-en-us-30GB \
ubuntu \
--location "West US" \
--ssh \
--no-ssh-password \
--ssh-cert ~/.ssh/ssh-public-key.pem
```

Then install snappy dev tools on it, and checkout the example apps.

```
sudo add-apt-repository ppa:snappy-dev/beta
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install snappy-tools bzr
bzr branch lp:~snappy-dev/snappy-hub/snappy-examples
cd snappy-examples/python-xkcd-webserver
snappy build .
```
This will generate a xkcd-webserver_0.3.3_all.snap file. In order to deploy a snap file to a remote Ubuntu Core machine, you can use ssh urls. This requires you to upload your private key to pat-ubuntu, and configure ssh there to connect to pat-snappy. From the Mac where I do development, my ~/.ssh/config has an entry:

```
Host pat-ubuntu
    HostName pat-ubuntu.cloudapp.net
    Port 22
    User ubuntu
    IdentityFile ~/.ssh/ssh-private-key.key
```

Upload your private key to pat-ubuntu

```
scp ~/.ssh/ssh-private-key.key pat-ubuntu:/home/ubuntu/.ssh/
ssh pat-ubuntu
```

Configure ssh on pat-ubuntu to connect to pat-snappy

```
vi ~/.ssh/config
Host pat-snappy
    HostName pat-snappy.cloudapp.net
    Port 22
    User ubuntu
    IdentityFile /home/ubuntu/.ssh/ssh-private-key.key
```

Then you can push the snappy app from pat-ubuntu to pat-snappy.

```
snappy-remote --url=ssh://pat-snappy install ./xkcd-webserver_0.3.3_all.snap
```

In pat-snappy

```
snappy versions -a
Part            Tag   Installed  Available  Fingerprint     Active  
ubuntu-core     edge  90         -          6b10509a70be67  *       
docker          edge  1.3.2.007  -          b1f2f85e77adab  *       
hello-world     edge  1.0.3      -          02a04059ae9304  *       
xkcd-webserver  edge  0.3.3      -          968e08b6741085  *  
```

xkcd-webserver is a simple Python webserver that serves randon xkcd images. It makes testing more pleasant.

```
cat /apps/xkcd-webserver/0.3.3/bin/xkcd-webserver
#!/usr/bin/python3

import os
import sys
import urllib.request

from http.server import HTTPServer, SimpleHTTPRequestHandler
...
```

On you client machine, or the portal, create an endpoint on port 80 for pat-snappy.

```
azure vm endpoint create pat-snappy-2 80 80
```

Then browse to http://pat-snappy.cloudapp.net/, you should get a nice xkcd comic.

<img src="/img/snappy-xkcd.png"/>

## Modify and update your snappy apps

Let's enhance our app and update it. On pat-ubuntu, edit snappy-examples/python-xkcd-webserver/www/index.html, add some text in it. Then update the version number in snappy-examples/python-xkcd-webserver/meta/package.yaml

```
name: xkcd-webserver
version: 0.3.4
...
```
Build and deploy the new version:

```
cd snappy-examples/python-xkcd-webserver
snappy build .
snappy-remote --url=ssh://pat-snappy install ./xkcd-webserver_0.3.4_all.snap
```

Navigate to http://pat-snappy.cloudapp.net/, you should get the new version of your xkcd comic page.

<img src="/img/snappy-xkcd-updated.png"/>

## Going further

The workflow for snappy apps deployment involves registering a user [Ubuntu Software center and submitting your app there](https://myapps.developer.ubuntu.com/dev/click-apps/new/). Once this is done, users can find your app using snappy search, and update them using snappy update.
