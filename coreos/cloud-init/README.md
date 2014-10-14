# Getting a CoreOS cluster up and running on Azure

This documentation is subject to change. It relies on the current development image of CoreOS for Azure from @dcrawford. In this image, he fixed most of the issues from previous image: cloud-init file is base64 decoded, and picked up by coreos. $private_ipv4 variables are interpolated.

Use image at https://coreos.blob.core.windows.net/public/prod-test-3.vhd. First create an image in your subscription based on this blob.

```shell
azure vm disk upload --verbose https://coreos.blob.core.windows.net/public/prod-test-3.vhd http://<your-storage-account>.blob.core.windows.net/<your-container>/prod-test-3.vhd  <your storage key>
azure vm image create coreos-test-3 --location "West US" --blob-url http://<your-storage-account>.blob.core.windows.net/<your-container>/prod-test-3.vhd --os linux
```
Create a virtual network in Azure.

modify cloud-init.yaml with https://discovery.etcd.io/new discovery url, ssh key, name and hostname for each of the hosts you want to create. Here is an example [cloud-init.yml](/cloud-init.yml) file. Then create the VMs. These commands create ssh endpoints for easier debugging.

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
