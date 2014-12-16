# Azure CoreOS cluster deployment tool

This tutorial is part of [P@'s Linux on Azure series](/../../).

[Deploying a CoreOS cluster on Azure](../../../master/coreos/cloud-init/README.md) takes a lot of manual steps using the Azure Cross platform CLI. This tool, built using the Azure Python SDK, automates these steps.

## Prerequisites

### Python

* Python > 2.7 and Pip
* Azure Python SDK > 0.9.0

You can [follow the installation instructions](http://azure.microsoft.com/en-us/documentation/articles/python-how-to-install/), or on a Mac:
```
brew install python
sudo pip install azure
```

Check prerequisites:
```
python -c "import azure; print(azure.__version__)"
0.9.0
```

### Azure subscription id and management certificate

#### Azure subscription id

Get your Azure subscription id from the portal

<img src="/../../blob/master/img/azure-subscription.png"/>

#### <a name="certs"></a>Certificates

This script uses the [Azure Service Management API from the Azure Python SDK](http://azure.microsoft.com/en-us/documentation/articles/cloud-services-python-how-to-use-service-management/).

You will need 2 certificates in order to use this script: your azure management certificate, in pem format, and the ssh certificate in .cer format, as well as a sha1 thumbprint of this certificate.

Documentation for these is a bit confusing, so below are instructions for how to generate these.
In case you want to go to official documentation on this:
* [Create and Upload a Management Certificate for Azure](http://msdn.microsoft.com/en-us/library/azure/gg551722.aspx): go to Settings page in the Management Portal, and then click MANAGEMENT CERTIFICATES. Upload the .cer file. use the corresponding .pem file in the command line.
* [How to Use SSH with Linux on Azure](http://azure.microsoft.com/en-us/documentation/articles/virtual-machines-linux-use-ssh-key/)

I have filled a config file for openssl in [cert.conf](cert.conf) (should be present in your source directory if you checked that project out): feel free to edit it to configure the cert with your own values.

**If you don't provide a certificate and thumbprint via `--ssh-cert` and `ssh-thumb`, the script will automatically create one for you (using the code below).** If you're interested in the details, read http://azure.microsoft.com/en-us/documentation/articles/virtual-machines-linux-use-ssh-key/ for how to generate your ssh keys: pem, key, cer and sha1 thumbprint of the certificate. You can edit cert.conf to configure the cert with your own values.

#### Azure Management cert

```
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -config cert.conf -keyout azure-cert.pem -out azure-cert.pem
openssl  x509 -outform der -in azure-cert.pem -out azure-cert.cer
```

Upload azure.cer to your Azure subscription in the portal. Portal, go to the gear at the bottom, settings, go to certificate management tab, click upload, pick the azure-cert.cer file.

<img src="/../../blob/master/img/upload-azure-management-cert.png"/>

#### Ssh cert

```
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -config cert.conf -keyout ssh-cert.key -out ssh-cert.pem
chmod 600 ssh-cert.key
openssl  x509 -outform der -in ssh-cert.pem -out ssh-cert.cer
openssl x509 -in ssh-cert.pem -sha1 -noout -fingerprint | sed s/://g
SHA1 Fingerprint=44EF1BA225BE64154F7A55826CE56EA398C365B5
```

## Quick Example

```
./azure-coreos-cluster pat-coreos-cloud-service \
--subscription 9b5910a1-...-8e79d5ea2841 \
--azure-cert ~/.azure/azure-cert.pem \
--blob-container-url https://patcoreos.blob.core.windows.net/vhds/
```

Creates a 3 node cluster called pat-coreos-cloud-service.
use --num-nodes 5 option to bump it to create 5 instances instead of the default 3.
A more robust cluster would look like this:

```
./azure-coreos-cluster pat-coreos-cloud-service \
--ssh-cert ~/.ssh/ssh-cert.cer \
--ssh-thumb 44EF1BA225BE64154F7A55826CE56EA398C365B5 \
--subscription 9b5910a1-...-8e79d5ea2841 \
--azure-cert ~/.azure/azure-cert.pem \
--num-nodes 5 \
--location "East US" \
--vm-size Large \
--blob-container-url https://patcoreos.blob.core.windows.net/vhds/
```

## Usage

```
./azure-coreos-cluster -h
usage: azure-coreos-cluster [-h] [--version] --subscription SUBSCRIPTION --azure-cert
AZURE_CERT --blob-container-url BLOB_CONTAINER_URL
[--ssh-cert SSH_CERT]
[--ssh-thumb SSH_THUMB]
[--vm-size VM_SIZE]
[--vm-name-prefix VM_NAME_PREFIX]
[--availability-set AVAILABILITY_SET]
[--location LOCATION] [--ssh SSH]
[--coreos-image COREOS_IMAGE]
[--num-nodes NUM_NODES]
[--virtual-network-name VIRTUAL_NETWORK_NAME]
[--subnet-names SUBNET_NAMES]
[--custom-data CUSTOM_DATA]
[--discovery-service-url DISCOVERY_SERVICE_URL]
[--pip]
[--deis]
[--data-disk]
cloud_service_name

Create a CoreOS cluster on Microsoft Azure.

positional arguments:
cloud_service_name    cloud service name

optional arguments:
-h, --help                                    show this help message and exit
--version                                     show program's version number and exit
--subscription SUBSCRIPTION                   required Azure subscription id
--azure-cert AZURE_CERT                       required path to Azure cert pem file
--blob-container-url BLOB_CONTAINER_URL       required url to blob container where vm disk images
will be created, including /, ex: https://patcoreos.blob.core.windows.net/vhds/
--vm-size VM_SIZE                             optional, VM size [Small]
--vm-name-prefix VM_NAME_PREFIX               optional, VM name prefix [coreos]
--availability-set AVAILABILITY_SET           optional, name of availability set for cluster [coreos-as]
--location LOCATION                           optional, [West US]
--ssh SSH                                     optional, starts with 22001 and +1 for each machine in cluster
--ssh-cert SSH_CERT                           optional, pem certificate file with public key for ssh
--ssh-thumb SSH_THUMB                         optional, thumbprint of ssh cert
--coreos-image COREOS_IMAGE                   optional, [2b171e93f07c4903bcad35bda10acf22__CoreOS-Beta-494.1.0]
--num-nodes NUM_NODES                         optional, number of nodes to create (or add), defaults to 3
--virtual-network-name VIRTUAL_NETWORK_NAME   optional, name of an existing virtual network to which we will add the VMs
--subnet-names SUBNET_NAMES                   optional, subnet name to which the VMs will belong
--custom-data CUSTOM_DATA                     optional, path to your own cloud-init file
--discovery-service-url DISCOVERY_SERVICE_URL optional, url for an existing cluster discovery service. Else we will generate one.
--pip                                         optional, assigns public instance ip addresses to each VM
--deis                                        optional, if you provision a CoreOS cluster to deploy deis, this option will fetch deis specific cloud-init and generate a new discovery token in it automatically
--data-disk                                   optional, creates a data disk in same blob container as the vm, and attaches it to the VM
```

See official CoreOS Azure documentation [Running CoreOS on Azure](https://coreos.com/docs/running-coreos/cloud-providers/azure/) for CoreOS image names. Or install Azure CLI and run:
```
azure vm image list|grep CoreOS
```

[Instance-Level Public IP Addresses](http://msdn.microsoft.com/en-us/library/azure/dn690118.aspx) is right now in preview, and you are limited to 5 per subscription. The --pip option is useful for setting up a [CoreOS cluster for Deis](../../../master/coreos/deis/README.md). This option is not implemented yet.

For now, virtual-network and subnet options are not implemented yet.

## data-disk

When you use the --data-disk option, a 10Gb data disk is created and attached to your VM as /dev/sdc. You still need to mount it at startup, typically using a mount unit in your cloud-ini.yml. This is an example of mounting it in /var/lib/docker.

```yml
- name: format-ephemeral.service
  command: start
  content: |
    [Unit]
    Description=Formats the ephemeral drive
    [Service]
    Type=oneshot
    RemainAfterExit=yes
    ExecStart=/usr/sbin/wipefs -f /dev/sdc
    ExecStart=/usr/sbin/mkfs.btrfs -f /dev/sdc
- name: var-lib-docker.mount
  command: start
  content: |
    [Unit]
    Description=Mount ephemeral to /var/lib/docker
    Requires=format-ephemeral.service
    After=format-ephemeral.service
    Before=docker.service
    [Mount]
    What=/dev/sdc
    Where=/var/lib/docker
    Type=btrfs
```
