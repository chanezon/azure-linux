# Azure CoreOS cluster deployment tool

[Deploying a CoreOS cluster on Azure](../../../master/coreos/cloud-init/README.md) takes a lot of manual steps using the Azure Cross platform CLI. This tool, built using the Azure Python SDK, automates these steps.

## Prerequisites

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

* Azure subscription id and management certificate
This script uses the [Azure Service Management API from the Azure Python SDK](http://azure.microsoft.com/en-us/documentation/articles/cloud-services-python-how-to-use-service-management/). See the documentation for how to get your subscription id and certificate. The docs will also be useful  if you want to customize the script.

If you don't provide a certificate and thumbprint via `--ssh-cert` and `ssh-thumb`, the script will automatically create one for you (using the code below). If you're interested in the details, read http://azure.microsoft.com/en-us/documentation/articles/virtual-machines-linux-use-ssh-key/ for how to generate your ssh keys: pem, key, cer and sha1 thumbprint of the certificate. You can edit cert.conf to configure the cert with your own values.
```
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -config cert.conf -keyout ssh-cert.key -out ssh-cert.pem
chmod 600 ssh-cert.key
openssl  x509 -outform der -in ssh-cert.pem -out ssh-cert.cer
openssl x509 -in ssh-cert.pem -sha1 -noout -fingerprint | sed s/://g
SHA1 Fingerprint=44EF1BA225BE64154F7A55826CE56EA398C365B5
```

Warning: you will need 2 certificates in order to use this script: your azure management certificate, in pem format, and the ssh certificate in .cer format, as well as a sha1 thumbprint of this certificate.

For the Azure management certificate, if you don't have one, generate one as shown above, then upload the .cer file to Azure as explained in [Create and Upload a Management Certificate for Azure](http://msdn.microsoft.com/en-us/library/azure/gg551722.aspx): go to Settings page in the Management Portal, and then click MANAGEMENT CERTIFICATES. Upload the .cer file. use the corresponding .pem file in the command line.

## Quick Example

```
./azure-coreos-cluster pat-coreos-cloud-service \
--subscription 9b5910a1-8e79d5ea2841 \
--azure-cert ~/.azure/9b5910a1-8e79d5ea2841.pem \
--blob-container-url https://patcoreos.blob.core.windows.net/vhds/
```

Creates a 3 node cluster called pat-coreos-cloud-service.
use --num-nodes 5 option to bump it to create 5 instances instead of the default 3.

## Usage

```
./azure-coreos-cluster -h
usage: azure-coreos-cluster [-h] [--version] --ssh-cert SSH_CERT --ssh-thumb
SSH_THUMB --subscription SUBSCRIPTION --azure-cert
AZURE_CERT --blob-container-url BLOB_CONTAINER_URL
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
--ssh-cert SSH_CERT                           optional, pem certificate file with public key for ssh (if ommited, a cert will be generated)
--ssh-thumb SSH_THUMB                         optional, thumbprint of ssh cert (if ommited, the thumprint of the generated cert will be used)
--coreos-image COREOS_IMAGE                   optional, [2b171e93f07c4903bcad35bda10acf22__CoreOS-Beta-494.1.0]
--num-nodes NUM_NODES                         optional, number of nodes to create (or add), defaults to 3
--virtual-network-name VIRTUAL_NETWORK_NAME   optional, name of an existing virtual network to which we will add the VMs
--subnet-names SUBNET_NAMES                   optional, subnet name to which the VMs will belong
--custom-data CUSTOM_DATA                     optional, path to your own cloud-init file
--discovery-service-url DISCOVERY_SERVICE_URL optional, url for an existing cluster discovery service. Else we will generate one.
--pip                                         optional, assigns public instance ip addresses to each VM
--deis                                        optional, automatically gets deis\' recommended CoreOS configuration file is set to `true`
```

See official CoreOS Azure documentation [Running CoreOS on Azure](https://coreos.com/docs/running-coreos/cloud-providers/azure/) for CoreOS image names. Or install Azure CLI and run:
```
azure vm image list|grep CoreOS
```

[Instance-Level Public IP Addresses](http://msdn.microsoft.com/en-us/library/azure/dn690118.aspx) is right now in preview, and you are limited to 5 per subscription. The --pip option is useful for setting up a [CoreOS cluster for Deis](../../../master/coreos/deis/README.md). This option is not implemented yet.

For now, virtual-network and subnet options are not implemented yet.
