# Operator for gluster-subvol

This is a "helm" operator to deploy the kubernetes components of gluster-subvol.
That includes both the flexvol plugin and the recycler pods.

# Usage

## Starting the operator

Create the `gluster-subvol` namespace and start the operator:

```
$ kubectl create namespace gluster-subvol
$ kubectl -n gluster-subvol apply -f gluster-subvol-operator/deploy/crds/gluster-subvol_v1alpha1_flexvol_crd.yaml
$ kubectl -n gluster-subvol apply -f gluster-subvol-operator/deploy/service_account.yaml
$ kubectl -n gluster-subvol apply -f gluster-subvol-operator/deploy/role.yaml
$ kubectl -n gluster-subvol apply -f gluster-subvol-operator/deploy/role_binding.yaml
$ kubectl -n gluster-subvol apply -f gluster-subvol-operator/deploy/operator.yaml
```

## Create a Secret to hold the CA TLS keys

The same CA key & pem used to generate keys for the Gluster servers needs to be
inserted into a Kubernetes Secret so that client keys can be generated.

Assuming the CA keys are `gluster_ca.key` and `gluster_ca.pem`, the secret can
be created via:

```
$ kubectl create secret generic gluster-ca-key --from-file=ca.key=gluster_ca.key --from-file=ca.pem=gluster_ca.pem
secret "gluster-ca-key" created
```

Enter the name of this secret in the `flexvol` custom resource, below.

## Create the custom resource

The `flexvol` CR controlls the DaemonSet that deploys the flexvol plugin to the
nodes.

```yaml
apiVersion: gluster-subvol.gluster.org/v1alpha1
kind: Flexvol
metadata:
  name: flex
spec:
  # Path on the host to write the plugin (optional)
  flexvolPath: "/usr/libexec/kubernetes/kubelet-plugins/volume/exec"
  # Override the plugin installer image (optional)
  installerImage: "quay.io/gluster/gluster-subvol-plugin:latest"
  # Name of the secret holding the ca.key and ca.pem
  tlsSecret: "gluster-ca-key"
```

## (OLD)

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
  tlsSecret: "gluster-ca-key"
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
