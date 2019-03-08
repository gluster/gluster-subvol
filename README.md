# Overview

[![Build
Status](https://travis-ci.org/gluster/gluster-subvol.svg?branch=master)](https://travis-ci.org/gluster/gluster-subvol)

This repo contains files necessary to use subdirectories of Gluster volumes as
persistent volumes in Kubernetes and OpenShift. It consists of three main items:

## glfs-subvol

This is a a flex volume plugin to allow mounting Gluster subdirectories into
containers.

## volcreator

This is a script that can be run on a Gluster server to pre-create the
subdirectories and establish quotas.

## volrecycler

[![Docker Repository on
Quay](https://quay.io/repository/gluster/gluster-subvol-volrecycler/status
"Docker Repository on
Quay")](https://quay.io/repository/gluster/gluster-subvol-volrecycler)

`image: quay.io/gluster/gluster-subvol-volrecycler`

This is a pod that is run in the cluster to watch for PVs that get released. It
deletes any data contained in them and marks them as available for use again.

---
# License

This code is licensed under Apache v2.0 with the exception of JQ which is
covered by the MIT license (see [COPYING_JQ](glfs-subvol/COPYING_JQ)).
