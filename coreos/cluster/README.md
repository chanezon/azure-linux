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
This script uses the [Azure Service Management API from the Azure Python SDK](http://azure.microsoft.com/en-us/documentation/articles/cloud-services-python-how-to-use-service-management/). See the documentation for how to get your subscription id and certifcate. The docs will also be useful  if you want to customize the script.

## Quick Example

```
azure-coreos-cluster pat-coreos-cloud-service \
--ssh-cert ~/.ssh/ssh-public-cert.pem \
--subscription-id 9b5910a1-8e79d5ea2841 \
--azure-cert ~/.azure/ 9b5910a1-8e79d5ea2841.pem
```

Creates a 3 node cluster called pat-coreos-cloud-service.

## Usage

```
Usage: azure-coreos-cluster [options] <cloud-service-name>

Options:

-h, --help                              output usage information
-V, --version                           output the version number
--subscription                          required, Azure subscription id
--azure-cert <pem-file>                 required, path to Azure cert pem file
--ssh-cert <Your pem file for ssh>      required, pem file with public key for ssh
--vm-size <size>                        optional, VM size [Small]
--vm-name-prefix <prefix>               optional, VM name prefix [coreos]
--availability-set <name>               optional, name of availability set for cluster [coreos-as]
--location <location>                   optional, [West US]
--ssh <ssh-port-start>                  optional, starts with 22001 and +1 for each machine in cluster
--virtual-network-name <vnet-name>      optional, name of virtual network we create for the cluster
--subnet-names <list>                   optional, comma-delimited subnet names
--custom-data <cloud-init-file.yml>     optional, your own cloud-init file, by default we use ...
--coreos-image <image>                  optional, [2b171e93f07c4903bcad35bda10acf22__CoreOS-Beta-494.1.0]
--num-nodes <number>                    optional, number of nodes to create (or add), defaults to 3
--discovery-service-url <url>           optional, url for an existing cluster discovery service. Else we'll generate one.
--pip                                   optional, assigns public instance ip addresses to each VM
```

See official CoreOS Azure documentation [Running CoreOS on Azure](https://coreos.com/docs/running-coreos/cloud-providers/azure/) for CoreOS image names. Or install Azure CLI and run:
```
azure vm image list|grep CoreOS
```

[Instance-Level Public IP Addresses](http://msdn.microsoft.com/en-us/library/azure/dn690118.aspx) is right now in preview, and you are limited to 5 per subscription. The --pip option is useful for setting up a [CoreOS cluster for Deis](../../../master/coreos/deis/README.md). This option is not implemented yet.

For now, only the 3 required parameters are implemented. All the other take default values.
