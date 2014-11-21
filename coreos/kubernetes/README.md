# Installing Kubernetes on a CoreOS cluster on Azure

This tutorial is part of [P@'s Linux on Azure series](/../../).

[Kubernetes](https://github.com/googlecloudplatform/kubernetes) is "an open source implementation of container cluster management". It was created by Google, and is inspired by Google internal container management infrastructure. Microsoft participates in this project, as well as developers from many other industry players.

There is a tutorial about how to setup Kubernetes on Azure in Kubernetes documentation: [Kubernetes, Getting started on Microsoft Azure](https://github.com/GoogleCloudPlatform/kubernetes/blob/master/docs/getting-started-guides/azure.md). But right now it is broken at git HEAD, valid for Kubernetes 0.3. It uses uses Ubuntu images and OpenVPN for networking overlay.

This tutorial explains how to install Kubernetes on a CoreOS cluster on Azure, expanding on the [Installing a CoreOS cluster on Azure](/coreos/cloud-init/README.md) tutorial. I won't repeat everything that is already in the in CoreOS tutorial, just explain the Kubernetes specific bits.

The main issue installing Kubernetes on Azure is networking: [Kubernetes needs to assign 1 IP address per pod](https://github.com/GoogleCloudPlatform/kubernetes/blob/master/docs/design/networking.md), which works fine on Google Cloud Platform, where [advanced routing](https://cloud.google.com/compute/docs/networking#routing) allows you to configure your VMs so that each get assigned a /24 address space. On Azure today, you need to leverage some kind of overlay network to accomplish that. There are different approaches in how to do this:
* [Weave for Kubernetes on CoreOS](http://weaveblog.com/2014/11/11/weave-for-kubernetes/) seems promising, and should be a good approach for Azure
* [Deploying Kubernetes on CoreOS with Fleet and Flannel](https://github.com/kelseyhightower/kubernetes-fleet-tutorial/blob/master/README.md) the other main approach

Let's try them with our CoreOS cluster on Azure.

## Weave approach

