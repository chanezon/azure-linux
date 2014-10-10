# Getting a CoreOS cluster up and running on Azure

This is subject to change. Many hacks to workaround waagent for CoreOS not being finalized yet.

Use image at https://patcoreos.blob.core.windows.net/vm-images/pat-coreos-3-202407-50035-os-2014-10-08.vhd
It includes the modified waagent at https://github.com/chanezon/azure-linux/blob/master/coreos/cloud-init/waagent
This agent includes dcrawford translate pull request https://github.com/Azure/WALinuxAgent/pull/47/files and adds a hack that copies the cloud-init file to /usr/share/oem/cloud-config.yml 
With this, you need to reboot for cloud-init to be picked up.
You also need to rm /etc/machine-id

Current CoreOS on Azure does not support $public_ipv4 and $private_ipv4 interpolation in cloud-init file https://coreos.com/docs/cluster-management/setup/cloudinit-cloud-config/
The cloud-init file https://github.com/chanezon/azure-linux/blob/master/coreos/cloud-init/master-with-ip.yaml contains a nice hack inspired by paulczar in https://github.com/coreos/coreos-cloudinit/issues/195 that brute forces it for etcd and fleet.

On the Azure side, I have one vm per cloud service, to avoid messing with port mapping, and ssh setup for easier debugging. All the vms are in the same virtual network.
Production setup would probably use one cloud-service per tier, with either an internal load balancer http://msdn.microsoft.com/library/azure/dn690121.aspx, or a load balanced set http://msdn.microsoft.com/en-us/library/azure/dn655055.aspx

Here are the steps
modify master-with-ip.yaml with https://discovery.etcd.io/new discovery url, name and hostname
for i in [1..n]
create n of these files
cloud-init-i.yml

```
wget https://patcoreos.blob.core.windows.net/vm-images/pat-coreos-3-202407-50035-os-2014-10-08.vhd
azure vm image create mycoreosimage ./pat-coreos-3-202407-50035-os-2014-10-08.vhd -o linux -l "West US"
```
for i in [1..n] fo these steps
```
azure vm create -l "West US" --ssh --ssh-cert ~/.ssh/azureCert.pem pat-coreos-1 mycoreosimage --virtual-network-name pat-coreos-network username password --custom-data ~/code/coreos/master-with-ip.yaml
#configure ssh to pick up your private key
ssh username@pat-coreos-1.cloudapp.net
sudo rm /etc/machine-id 
sudo reboot
ssh username@pat-coreos-1.cloudapp.net
#check that etcd and fleet are good
etcdctl ls --recursive
fleetctl list-machines
```

Then you can start playing with fleet on your cluster.
Have fun!
