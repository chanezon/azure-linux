# Installing Weave Docker networking on a CoreOS cluster on Azure

This tutorial is part of [P@'s Linux on Azure series](/../../).

[Weave](https://github.com/zettio/weave#readme) is an open source project to create "a virtual network that connects Docker containers deployed across multiple hosts". It allows you to create a virtual network across different clouds.

<img src="https://raw.githubusercontent.com/zettio/weave/master/docs/virtual-network.png"/>

The technical approach of this tutorial was inspired by the Weave blog article [Automated provisioning of multi-cloud weave network with Terraform](http://weaveblog.com/2014/12/18/automated-provisioning-of-multi-cloud-weave-network-terraform/), where they deploy a Weave network across AWS and Google Cloud Platform.

Since there is not yet a Terraform driver for Microsoft Azure, I'm using the azure-coreos-cluster script, with a post processing step.

## Deploying a CoreOS cluster for Weave

To deploy the cluster, you will use the [Azure CoreOS cluster deployment script](../../coreos/cluster/README.md). Read that document to understand how to get your subscription id, Azure and ssh certificates.

In order to install Weave on the cluster, you need to deploy the cluster using the [Weave cloud-init file in this directory](../weave/weave.yml).

You also need to use the --attach-drive option of the cluster provisioning script: the cloud-init file will mount that external drive to /var/lib/docker. This ensures a better performance for Docker, and allows the docker image cache to survive reboots.

Before launching the command, edit weave.yml and add discovery usl, generated using https://discovery.etcd.io/new.

When it starts, Weave needs the list of all ip addresses for machines in the cluster. In order to configure this, the cloud-init file specifies an environment file where these ip addresses are specified, as well as the weave password, and dns address.
```
[Service]
EnvironmentFile=/etc/weave.env
ExecStartPre=/opt/bin/weave launch -password ${WEAVE_LAUNCH_PASSWORD} $WEAVE_LAUNCH_KNOW_NODES
ExecStartPre=/opt/bin/weave launch-dns $WEAVE_LAUNCH_DNS_ARGS -debug
```

When provisioning the cluster, we don't know these ip addresses yet. So we will use the --ouput option of the cluster deployment tool, which will generate a json cluster state file containing metadata about the cluster. The useful metadata here is the list of machines, ssh ports, path to ssh certificate and unix user for the cluster. We will use this cluster state file in a post processing script after the cluster is deployed.

Deploy the cluster with a command like this, from the cluster directory of this repository:
```
./azure-coreos-cluster pat-coreos-cloud-service \
--ssh-cert ~/.ssh/ssh-cert.cer \
--ssh-thumb 44EF1BA225BE64154F7A55826CE56EA398C365B5 \
--subscription 9b5910a1-...-8e79d5ea2841 \
--azure-cert ~/.azure/azure-cert.pem \
--num-nodes 5 \
--location "West US" \
--vm-size Large \
--custom-data ../weave/weave.yml \
--blob-container-url https://patcoreos.blob.core.windows.net/vhds/ \
--data-disk \
--output
```

This will generate a cluster state file in the current directory under the default name [cloud-service-name].json. You can also specify your own name for it as the --output parameter. This state file contains all the args used in the cluster script to create the cluster, all the ip addresses, and the informations allowing to ssh into each of the cluster's machines. Here is [a sample cluster state file](../cluster/pat-coreos-cloud-service.json).

Before running the post processing script, check in the Azure console that all instances of the cluster have finished deploying and are in running state.

## Post processing

The post processing script, in the cluster directory, [azure-coreos-weave](../cluster/azure-coreos-weave), takes the cloud service name as a parameter. It will look for a state file named [cloud-service-name].json in the current directory.

You can pass to it an optional parameter --weave-password. If not, it will use the default 'f00bar' password.

This script will ssh into every instance, using information from the state file, create the /etc/weave.env file defining $WEAVE_LAUNCH_PASSWORD $WEAVE_LAUNCH_KNOW_NODES and $WEAVE_LAUNCH_DNS_ARGS environment variables. By default it uses 10.10.1.1{i}/16 where i is the index number for the instance in the cluster. You can modify this in the script if needed. Then it will restart the weave service on each machine in the cluster: ```sudo systemctl restart weave.service```

./azure-coreos-weave pat-coreos-cloud-service

## Adding machines to the cluster

You would need to tweak the azure-coreos-cluster script to add machines to the cluster. If you do, for weave configuration, you don't need to modify all the environment files: you can add [new machines to the network](http://zettio.github.io/weave/features.html#dynamic-topologies) by running weave on the new machine passing to it one of the existing peers. Or you can run ```weave connect $NEW_HOST``` on one of the existing hosts, where $NEW_HOST is the ip of the host you added.

## Testing Weave status

Your cluster should be up and running with weave configured for virtual networking. Let's test it.
ssh to the first machine in the cluster, and run sudo weave status: this should list the peers in the cluster.
```
ssh -i ~/.ssh/ssh-cert.key core@pat-coreos-cloud-service.cloudapp.net -p 22001
sudo weave status
core@pat-coreos-cloud-service-coreos-0 ~ $ sudo weave status
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

## Testing weave dns service

[According to WeaveDNS documentation](https://github.com/zettio/weave/tree/master/weavedns#using-weavedns) you need to add the --with-dns flag to weave for the container to use the WeaveDNS, and giving any container a hostname in the .weave.local domain registers it in weaveDNS.

Let's ssh to 2 of our cluster machines and do the following:
```
ssh -i ~/.ssh/ssh-cert.key core@pat-coreos-cloud-service.cloudapp.net -p 22001
sudo weave run --with-dns 10.1.1.25/24 -ti -h p1.weave.local ubuntu
Unable to find image 'ubuntu' locally
Pulling repository ubuntu
Status: Downloaded newer image for ubuntu:latest
bb7299787b14975d70eb3cd04016c5a0ae34b35d7b8ea7fa49f428062969a0a1
```

```
ssh -i ~/.ssh/ssh-cert.key core@pat-coreos-cloud-service.cloudapp.net -p 22002
sudo weave run --with-dns 10.1.1.26/24 -ti -h p2.weave.local ubuntu
Unable to find image 'ubuntu' locally
Pulling repository ubuntu
Status: Downloaded newer image for ubuntu:latest
604f8137c6485015f8b96ca6dd8aa3b8f827646b9cc2c6f2d087c1d1267b1ecf
```

Then on the first machine
```
sudo docker attach bb7299787b14975d70eb3cd04016c5a0ae34b35d7b8ea7fa49f428062969a0a1
root@p1:/# ping p2.weave.local
PING p2.weave.local (10.1.1.26) 56(84) bytes of data.
64 bytes from p2.weave.local (10.1.1.26): icmp_seq=1 ttl=64 time=2.85 ms
64 bytes from p2.weave.local (10.1.1.26): icmp_seq=2 ttl=64 time=2.52 ms
```

On the second machine:
```
sudo docker attach 604f8137c6485015f8b96ca6dd8aa3b8f827646b9cc2c6f2d087c1d1267b1ecf
root@p2:/# ping p1.weave.local
PING p1.weave.local (10.1.1.25) 56(84) bytes of data.
64 bytes from p1.weave.local (10.1.1.25): icmp_seq=1 ttl=64 time=1.17 ms
64 bytes from p1.weave.local (10.1.1.25): icmp_seq=2 ttl=64 time=1.34 ms
64 bytes from p1.weave.local (10.1.1.25): icmp_seq=3 ttl=64 time=1.22 ms
```

<img src="/img/weave-test.png"/>

Weave and WeaveDNS now work on you CoreOS cluster: you can now control the network topology and naming of the Docker containers you provision on your CoreOS cluster with Weave. Weave also lets you add machines from other cloud providers to the network, as described in [Automated provisioning of multi-cloud weave network with Terraform](http://weaveblog.com/2014/12/18/automated-provisioning-of-multi-cloud-weave-network-terraform/).

Have fun with Weave, CoreOS, Docker and Azure!
