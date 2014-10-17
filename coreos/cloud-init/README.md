# Getting a CoreOS cluster up and running on Azure

This documentation is subject to change. It relies on the current development image of CoreOS for Azure from @dcrawford. In this image, he fixed most of the issues from previous image: cloud-init file is base64 decoded, and picked up by coreos. $private_ipv4 variables are interpolated.

## Create the VM image in your subscription

Use image at http://alpha.release.core-os.net/amd64-usr/469.0.0/coreos_production_azure_image.vhd.bz2. First create an image in your subscription based on this blob (actually this is a bz2 compressed image, so you'll need to download it on a vm, uncompress it, and upload it to your storage account. Very soon there will be a public vhd image in the gallery to pull from).

```shell
azure vm disk upload --verbose https://coreos.blob.core.windows.net/public/prod-test-3.vhd http://<your-storage-account>.blob.core.windows.net/<your-container>/prod-test-3.vhd  <your storage key>
azure vm image create coreos-test-3 --location "West US" --blob-url http://<your-storage-account>.blob.core.windows.net/<your-container>/prod-test-3.vhd --os linux
```

## Create a virtual network in Azure.

Use the portal, or commandline.

## Create your cloud-init config file

modify cloud-init.yaml with https://discovery.etcd.io/new discovery url, ssh key, name and hostname for each of the hosts you want to create. Here is an example [cloud-init.yml](cloud-init.yml) file. Then create the VMs. These commands create ssh endpoints for easier debugging.

## A note on ssh keys

If you follow the [Azure documentation to create your ssh keys](http://azure.microsoft.com/en-us/documentation/articles/virtual-machines-linux-use-ssh-key/), using openssl, you will end up with a ~/.ssh/my_private_key.key and ~/.ssh/my_public_key.pem files. openssh understands the private key format from openssl, but the [public key format for openssl and openssh are different](http://security.stackexchange.com/questions/32768/converting-keys-between-openssl-and-openssh). When you provision a VM, Azure will do the conversion for you and place the ssh public key in yourusername/.ssh/authorized_keys. You need that public ssh key in the ssh format in your cloud-init.yml.
In order to generate the public key in openssh format from your openssl cert, you need to use ssh-keygen on your private key.

```shell
ssh-keygen -y -f ~/.ssh/my_private_key.key
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDOC4ZPy3a+F/DRQefLG/IteM00PYpJlc4Mga7S2mLv86aglqfAgXTHxXHho3ggfRRlxvLnj
```
Use that as the value for the ssh_authorized_keys: entry in your cloud-init file.
What this will do is that it will add this key in authorized_keys for user core, in /home/core/.ssh/authorized_keys.

## Create the CoreOS VMs for your cluster

```shell
azure vm create -l "West US" --ssh --ssh-cert ~/.ssh/<Your pem file for ssh>.pem <hostname> <imagename>  --virtual-network-name <virtual network name> username password --custom-data ~/<cloud-init-file>.yml
```

Then check your cluster:
```shell
ssh username@hostname.cloudapp.net
sudo etcdctl ls --recursive
sudo fleetctl list-machines
MACHINE		IP		METADATA
415162a4...	10.0.0.5	region=us-west
7c7f60e0...	10.0.0.4	region=us-west
```

Then you can start playing with fleet on your cluster.

In this example cloud-init file, I use $private_ipv4, which will work for an Azure only cluster: all VMs being in the same virtual network, they can talk to each other. If you want to create a multi-cloud cluster, or connect to fleet from a remote machine, follow instructions at https://coreos.com/docs/cluster-management/setup/cloudinit-cloud-config/, use $public_ipv4 and open an endpoint on port 4001 from Azure.

```shell
azure vm endpoint create <hostname> 4001 4001
```

Have fun with CoreOS on Azure!

## Configuring a remote fleet client

If you want to manage your cluster with fleet from a remote client, on a Mac, you need to build fleetctl on Mac.

```shell
git clone https://github.com/coreos/fleet.git
cd fleet/
./build
cp bin/fleetctl /usr/local/bin
```

fleetctl client tool uses SSH to interact with a fleet cluster (cf https://github.com/coreos/fleet/blob/master/Documentation/using-the-client.md#remote-fleet-access & https://github.com/coreos/fleet/blob/master/Documentation/deployment-and-configuration.md). You need to configure ssh to use the private key for the public key you specified in cloud-init file. By default, fleetctl uses the core user for ssh tunneling. [fleetctl issue 536](https://github.com/coreos/fleet/issues/536) adds a --ssh-username flag but it has not been merged yet. So you In order for fleetctl to use your private key, you need to use [ssh-add](http://linux.die.net/man/1/ssh-add) and ssh-agent for your session.
```shell
ssh-add ~/.ssh/my_private_key.key
fleetctl --tunnel <hostname>.cloudapp.net:22 list-machines
MACHINE IP METADATA
415162a4... 10.0.0.5 region=us-west
7c7f60e0... 10.0.0.4 region=us-west
```
