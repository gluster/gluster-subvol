# Gluster subvol

## Overview

**Project status:** (Mar 2020) The code in this repository is no longer under
active development. If you are interested in helping to maintain this project,
please open an issue or send mail to `gluster-devel@gluster.org`. Assuming no additional interest, this repo will be archived soon.

------

[![Build
Status](https://travis-ci.org/gluster/gluster-subvol.svg?branch=master)](https://travis-ci.org/gluster/gluster-subvol)

This repo contains files necessary to use subdirectories of Gluster volumes as
persistent volumes in Kubernetes and OpenShift. It consists of several items:

## glfs-subvol

[![Docker Repository on
Quay](https://quay.io/repository/gluster/gluster-subvol-plugin/status "Docker
Repository on Quay")](https://quay.io/repository/gluster/gluster-subvol-plugin)

`image: quay.io/gluster/gluster-subvol-plugin`

This is a a flex volume plugin to allow mounting Gluster subdirectories into
containers.

## subvol-operator

[![Docker Repository on
Quay](https://quay.io/repository/gluster/gluster-subvol-operator/status "Docker
Repository on
Quay")](https://quay.io/repository/gluster/gluster-subvol-operator)

`image: quay.io/gluster/gluster-subvol-operator`

This is a [Helm](https://helm.sh)-based operator created with the
[operator-sdk](https://github.com/operator-framework/operator-sdk). It is
designed to deploy the flexvol plugin (glfs-subvol) via a DaemonSet and the
recycler(s) for the associated supervols (volrecycler).

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
