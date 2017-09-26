# Overview

This repo contains files necessary to use subdirectories of Gluster volumes as
persistent volumes in Kubernetes and OpenShift. It consists of three main items:

1. `glfs-subvol`  
   This is a a flex volume plugin to allow mounting Gluster subdirectories into
containers.
2. `volcreator`  
   This is a script that can be run on a Gluster server to pre-create the
   subdirectories and establish quotas.
3. `volrecycler`  
   This is a pod that is run in the cluster to watch for PVs that get released.
   It deletes any data contained in them and marks them as available for use
   again.


---
# License

This code is licensed under Apache v2.0 with the exception of JQ which is
covered by the MIT license (see [COPYING_JQ](glfs-subvol/COPYING_JQ)).
