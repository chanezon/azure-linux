# Installing Weave software defined network on a CoreOS cluster on Azure

This tutorial is part of [P@'s Linux on Azure series](/../../).

[Weave](https://github.com/zettio/weave#readme) is an open source project to create "a virtual network that connects Docker containers deployed across multiple hosts". It allows you to create a virtual network across different clouds.

<img src="https://raw.githubusercontent.com/zettio/weave/master/docs/virtual-network.png"/>

The technical approach of this tutorial was inspired by the Weave blog article [Automated provisioning of multi-cloud weave network with Terraform](http://weaveblog.com/2014/12/18/automated-provisioning-of-multi-cloud-weave-network-terraform/), where they deploy a Weave network across AWS and Google Cloud Platform.

Since there is not yet a Terraform driver for Microsoft Azure, I'm using the azure-coreos-cluster script, with a post processing step.

## Deploying a CoreOS cluster for Weave

## Post processing

## Testing Weave
