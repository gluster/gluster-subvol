# Subvol recycler

This directory contains the recycler that cleans out PVs once they are released
(the associated PersistentVolumeClaim is deleted), deletes all the files in the
underlying directory, and marks the PV as ready to be used again.

## Overview

The recycler is run as a pod in the cluster, and it periodically searches for
PVs that:
* belong to a given Gluster cluster and volume
* are in the Released state

When the recycler script finds one or more PVs matching the above conditions, it
removes all files from the underlying subdirectory, then it patches the PV to
mark it Available.

## Usage

The recycler needs to mount the entire Gluster volume (using the in-tree Gluster
volume driver). To do this, there must be an Endpoint that represents the
Gluster cluster hosting the volume. See the contents of `volrecycler-ep.yml`:
```yaml
apiVersion: v1
kind: Endpoints
metadata:
  name: glusterfs-cluster
  namespace: glusterfs
subsets:
- addresses:
  - ip: 192.168.173.15
  - ip: 192.168.173.16
  - ip: 192.168.173.17
  ports:
  - port: 1
    protocol: TCP
```

The recycler also needs permission to:
* Use the Kubernetes API to query and modify the PVs
* Run the recycling script as `UID=0` so that it has sufficient permissions to
delete the files in the PV subdirectories.

This is handled by creating a service account with sufficient permissions. See
`volrecycler-sa.yml` for details. Also, for OpenShift, permitting a container to
run as UID 0 requires additional permissions. Once the service account has been
created, run:
```sh
$ oc adm policy add-scc-to-user anyuid system:serviceaccount:glusterfs:volrecycler-sa
```

The `volrecycler.yml` file has definitions for:
* A persistent volume representing the entire Gluster volume
* A claim (PVC) for that volume
* The pod description for the recycler, referencing the PVC.

Before running this pod, some configuration is necessary:
* The PersistentVolume needs to be modified to reference the Gluster cluster and
volume to be monitored. `Endpoint:` must match the endpoint that was created
earlier, and it must be the same as the list of gluster servers in the PVs we
will be recycling.
* The PersistentVolume and PersistentVolumeClaim need to be paired such that we
are assured of getting exactly this PV attached to the recycler pod.

  This is accomplished by putting a `claimRef:` on the PV that refers to the PVC
  and a `volumeName:` on the PVC that refers to the PV.

* The pod description needs to have `args:` set to refer to the IPs and volume
name from the Endpoint and PersistentVolume.

Once these changes are made, the pod can be started:
```sh
kubectl apply -f volrecycler.yml
```
