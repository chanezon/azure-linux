# Installing Weave Docker networking on a CoreOS cluster on Azure

This tutorial is part of [P@'s Linux on Azure series](/../../).

[Weave](https://github.com/zettio/weave#readme) is an open source project to create "a virtual network that connects Docker containers deployed across multiple hosts". It allows you to create a virtual network across different clouds.

<img src="https://raw.githubusercontent.com/zettio/weave/master/docs/virtual-network.png"/>

The technical approach of this tutorial was inspired by the Weave blog article [Automated provisioning of multi-cloud weave network with Terraform](http://weaveblog.com/2014/12/18/automated-provisioning-of-multi-cloud-weave-network-terraform/), where they deploy a Weave network across AWS and Google Cloud Platform.

Since there is not yet a Terraform driver for Microsoft Azure, I'm using the azure-coreos-cluster script, with a post processing step.

## Deploying a CoreOS cluster for Weave

https://github.com/chanezon/azure-linux/blob/master/coreos/weave/weave.yml
cloud config
add token to weave.yml
attach drive, mount var lib docker
weave start needs list of ip addresses
--output for command state file

./azure-coreos-cluster pat-coreos-weave-16 \
--ssh-cert ~/.ssh/azureCert.cer \
--subscription 9b5910a1-d954-4b45-85e8-8e79d5ea2841 \
--azure-cert ~/.azure/9b5910a1-d954-4b45-85e8-8e79d5ea2841.pem \
--ssh-thumb 44EF1BA225BE64154F7A55826CE56EA398C365B5 \
--custom-data /Users/pat/code/azure-linux/coreos/weave/weave.yml \
--num-nodes 3 --location "West US" --vm-size Large \
--data-disk --blob-container-url https://patcoreos.blob.core.windows.net/vhds/ \
--output

## Post processing

./azure-coreos-weave pat-coreos-weave-16

## Testing Weave

```
ssh -i /Users/pat/.ssh/azureCert.key core@pat-coreos-weave-16.cloudapp.net -p 22001
sudo weave status
core@pat-coreos-weave-16-coreos-0 ~ $ sudo weave status
weave router git-1b229fcc30c4
Encryption on
Our name is 7a:1f:19:60:e7:34
Sniffing traffic on &{9 65535 ethwe 56:43:5f:5a:22:17 up|broadcast|multicast}
MACs:
56:9d:be:0e:4d:dd -> 7a:4f:9b:2c:fd:4d (2015-01-28 00:23:41.485846305 +0000 UTC)
aa:a7:ac:66:76:d1 -> 7a:a7:1e:43:4f:92 (2015-01-28 00:24:42.042029336 +0000 UTC)
56:43:5f:5a:22:17 -> 7a:1f:19:60:e7:34 (2015-01-28 00:23:23.36528492 +0000 UTC)
c6:3b:c5:65:9a:26 -> 7a:1f:19:60:e7:34 (2015-01-28 00:23:25.86136052 +0000 UTC)
c2:76:e3:bd:fa:d9 -> 7a:1f:19:60:e7:34 (2015-01-28 00:23:29.203441778 +0000 UTC)
5a:04:6a:c8:58:0d -> 7a:4f:9b:2c:fd:4d (2015-01-28 00:23:40.676257413 +0000 UTC)
Peers:
Peer 7a:1f:19:60:e7:34 (v2) (UID 15408740147088391961)
-> 7a:4f:9b:2c:fd:4d [100.78.254.108:40009]
-> 7a:a7:1e:43:4f:92 [100.112.6.139:59008]
Peer 7a:4f:9b:2c:fd:4d (v2) (UID 7208304532370224693)
-> 7a:a7:1e:43:4f:92 [100.112.6.139:46892]
-> 7a:1f:19:60:e7:34 [100.78.162.54:6783]
Peer 7a:a7:1e:43:4f:92 (v2) (UID 13190790424639820357)
-> 7a:1f:19:60:e7:34 [100.78.162.54:6783]
-> 7a:4f:9b:2c:fd:4d [100.78.254.108:6783]
Routes:
unicast:
7a:4f:9b:2c:fd:4d -> 7a:4f:9b:2c:fd:4d
7a:1f:19:60:e7:34 -> 00:00:00:00:00:00
7a:a7:1e:43:4f:92 -> 7a:a7:1e:43:4f:92
broadcast:
7a:4f:9b:2c:fd:4d -> []
7a:a7:1e:43:4f:92 -> []
7a:1f:19:60:e7:34 -> [7a:4f:9b:2c:fd:4d 7a:a7:1e:43:4f:92]
Reconnects:
100.78.162.54:6783 (next try at 2015-01-28 00:28:12.376558404 +0000 UTC)
100.78.254.108:6783 (next try at 2015-01-28 00:26:56.549209901 +0000 UTC)
100.112.6.139:6783 (next try at 2015-01-28 00:28:07.117774503 +0000 UTC)
```
