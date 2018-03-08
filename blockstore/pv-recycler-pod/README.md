# Subvol recycler

This directory contains the recycler that cleans out PVs once they are released
(the associated PersistentVolumeClaim is deleted), deletes all the files in the
underlying directory, recreates the block device and formats it as XFS and marks
the PV as ready to be used again.

## Overview

The recycler is run as a pod in the cluster, and it periodically searches for
PVs that:
* belong to a given Gluster cluster and volume
* are in the Released state

When the recycler script finds one or more PVs matching the above conditions, it
removes all files from the underlying subdirectory, then it patches the PV to
mark it Available.

## Usage

The recycler is added to the Openshift or k8s cluster using the ansible playbook
at `../../volrecycler/ansible/install-recycler.yml.`

NOTE: The same ansible play is used to add the gluster-subvol recycler pod as
well to the cluster, the change is just in the image name used.

To install the recycler into an existing cluster the ansible role relies on the
values in the gluster_subvol_recycler dictionary.
gluster_subvol_recycler:
  supervol_name: <name of the supervol>
  gluster_endpoint: <kube ep name for the gluster cluster>
  gluster_endpoint_ips: <list of IPs for the Gluster servers>  (O)
  namespace: <kube namespace to run in>
  service_acct: <kube service account to use>
  create_sa: true | false                                      (O)
  enable_anyuid: true | false                                  (O)
  image: <container image for the recycler>

Entries marked w/ (O) are optional...
  create_sa: If true, it will create the service account, service_acct,with
    sufficient privileges. Defaults to false.
  enable_anyuid: If true, when creating the service account, add the scc
    to allow it to run pods as uid 0. (assumes presence of oc command and
    only has an effect if create_sa==true)
  gluster_endpoint_ips: If provided, it will create the endpoint named
    by gluster_endpoint, using the provided host list

The steps that are performed in the ansible play are as follows,
- Name space creation in the k8s cluster [reference](https://kubernetes.io/docs/tasks/administer-cluster/namespaces/#creating-a-new-namespace)
- Create service account for recycler [reference](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)
- Create service/endpoint for recycler [reference](https://kubernetes.io/docs/concepts/services-networking/service/)
- PV, PVC and recycler pod deployment [reference](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
