# Overview

This repo contains files necessary to use files in Gluster volumes as loop
mounted XFS formatted persistent volumes in Kubernetes and OpenShift. It
consists of three main items:

1. `flex-volume`
   This is a a flex volume plugin to allow loop mounting Gluster files as XFS
   based mounts into containers.
2. `creator`
   This is a script that can be run on a Gluster server to pre-create the
   files and format them with XFS.
3. `pv-recycler-pod`
   This is a pod that is run in the cluster to watch for PVs that get released.
   It deletes the files used as a loop device, recreates a fresh file for PV
   reuse and marks the PV as available.

Further the `test` directory contains tests, that help sanitize the scripts and
future changes to the same.

---
# License

This code is licensed under Apache v2.0 with the exception of JQ which is
covered by the MIT license (see [COPYING_JQ](glfs-subvol/COPYING_JQ)).
