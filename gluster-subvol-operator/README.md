# Operator for gluster-subvol

This is a "helm" operator to deploy the kubernetes components of gluster-subvol.
That includes both the flexvol plugin and the recycler pods.

# Usage

## Starting the operator

Create the `gluster-subvol` namespace and start the operator:

```
$ kubectl create namespace gluster-subvol
$ kubectl -n gluster-subvol apply -f gluster-subvol-operator/deploy/service_account.yaml
$ kubectl -n gluster-subvol apply -f gluster-subvol-operator/deploy/role.yaml
$ kubectl -n gluster-subvol apply -f gluster-subvol-operator/deploy/role_binding.yaml
$ kubectl -n gluster-subvol apply -f gluster-subvol-operator/deploy/operator.yaml
```

## Create the custom resource

The CR defines the supervols that will have recyclers.

```yaml
apiVersion: gluster-subvol.gluster.org/v1alpha1
kind: GlusterSubvol
metadata:
  name: subvol-config
spec:
  supervols:
    # Name of the supervol on the server
    - name: supervol01
      # List of IP addresses for the gluster cluster
      servers:
        - "192.168.121.6"
        - "192.168.121.228"
        - "192.168.121.222"
    - name: supervole2a03
      servers:
        - "192.168.121.6"
        - "192.168.121.228"
        - "192.168.121.222"
```

# Development

There are three ways to develop/test the components of the operator:

1. Build and run the operator in the cluster (just like in production).
1. Run the operator outside the cluster.
1. Run the chart via Helm & Tiller.

## Running outside the cluster

See the documentation for the operator SDK on running Helm operators locally.

## Running via Helm & Tiller

For developing and testing the chart, it's easiest to just run them without the
rest of the operator. To do this, the charts will be installed directly,
substituting a `values.yaml` file in place of the data that would normally be in
the operator's CR.

- Ensure you have Helm installed, with Tiller running in your test cluster.
- The chart to execute resides in:
`gluster-subvol-operator/helm-charts/glustersubvol`.

Create a `values.yaml` file with the same fields that you would normally place
in the `spec` section of the CR. For example:

```yaml
---
deployFlex: true
flexvolPath: /usr/libexec/kubernetes/kubelet-plugins/volume/exec
supervols:
  - name: supervol1
    servers:
      - "1.2.3.4"
      - "5.6.7.8"
  - name: supervol2
    servers:
      - "9.0.0.0"
flexvolImage: quay.io/gluster/gluster-subvol-flexplugin:latest
recyclerImage: quay.io/gluster/gluster-subvol-recycler:latest
tlsSecret: "mysecret"
```

You can then run the chart with a command like:

```
$ helm install --namespace subvol --name gs ./gluster-subvol-operator/helm-charts/glustersubvol -f values.yaml
NAME:   gs
LAST DEPLOYED: Tue Mar 12 11:50:31 2019
NAMESPACE: subvol
STATUS: DEPLOYED
...
```

Later, it can be removed via:

```
$ helm delete --purge gs
release "gs" deleted
```
