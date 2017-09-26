# Installation of flex volume plugin

This is a flex volume plugin that needs to be installed on each Kubernetes node.
Included in this directory is an ansible playbook (`install_plugin.yml`) that
performs the install. This playbook:
* Creates the directory for the plugin: `/usr/libexec/kubernetes/kubelet-plugins/volume/exec/rht~glfs-subvol`
* Copies both the plugin script `glfs-subvol` and the `jq` binary to that
directory.

Upon first install, it may be necessary to restart kubelet for it to find the
plugin.

# Usage
To use the plugin, include the following as a volume description.
```yaml
  flexVolume:
    driver: "rht/glfs-subvol"
    options:
      cluster: 192.168.173.15:192.168.173.16:192.168.173.17
      volume: testvol
      dir: 00/01
```
The required options for the driver are:
* `cluster`: A colon separated list of the Gluster nodes in the cluster. The
first will be used as the primary for mounting, and the rest will be listed as
backup volume servers.
* `volume`: This is the name of the large Gluster volume that is being
subdivided.
* `dir`: This is the path from the root of the volume to the subdirectory which
will be the volume.

The above example would use 192.168.173.15:/testvol/00/01 to hold the PV
contents.
