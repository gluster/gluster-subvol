# Installation of flex volume plugin

This is a flex volume plugin that needs to be installed on each Kubernetes node.
Included in this directory is an ansible playbook (`install_plugin.yml`) that
performs the install. This playbook:
* Creates the directory for the plugin:
`/usr/libexec/kubernetes/kubelet-plugins/volume/exec/rht~glfs-subvol`
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

# Diagnostics/debugging
The `glfs-subvol` script has logging for all of its actions to help diagnose
problems with the plugin. The logging settings are at the top of the script
file:
```sh
# if DEBUG, log everything to a file as we do it
DEBUG=1
DEBUGFILE='/tmp/glfs-subdir.out'
```
When `DEBUG` is `1`, all calls and actions taken by the plugin are logged to
`DEBUGFILE`. The following is an example of the log file:
```
[1505838156.815164701] > init
[1505838156.815164701] < 0 {"status": "Success", "capabilities": {"attach": false, "selinuxRelabel": false}}
[1505999412.727592392] > mount /var/lib/origin/openshift.local.volumes/pods/33a5af66-9ece-11e7-bbac-0cc47af70d00/volumes/rht~glfs-subvol/192.168.173.15-192.168.173.16-192.168.173.17-testvol-00-05 {"cluster":"192.168.173.15:192.168.173.16:192.168.173.17","dir":"00/05","kubernetes.io/fsGroup":"1000090000","kubernetes.io/fsType":"","kubernetes.io/pod.name":"filebench-8pn4m","kubernetes.io/pod.namespace":"testproj","kubernetes.io/pod.uid":"33a5af66-9ece-11e7-bbac-0cc47af70d00","kubernetes.io/pvOrVolumeName":"192.168.173.15-192.168.173.16-192.168.173.17-testvol-00-05","kubernetes.io/readwrite":"rw","kubernetes.io/serviceAccount.name":"default","volume":"testvol"}
[1505999412.727592392] volserver 192.168.173.15
[1505999412.727592392] backupservers 192.168.173.16:192.168.173.17
[1505999412.727592392] Using lockfile: /var/lock/glfs-subvol/192.168.173.15-testvol.lock
[1505999412.727592392] ! mount -t glusterfs -o backup-volfile-servers=192.168.173.16:192.168.173.17 192.168.173.15:/testvol /usr/libexec/kubernetes/kubelet-plugins/volume/exec/rht~glfs-subvol/mnt/192.168.173.15-testvol
[1505999412.727592392] ! mount --bind /usr/libexec/kubernetes/kubelet-plugins/volume/exec/rht~glfs-subvol/mnt/192.168.173.15-testvol/00/05 /var/lib/origin/openshift.local.volumes/pods/33a5af66-9ece-11e7-bbac-0cc47af70d00/volumes/rht~glfs-subvol/192.168.173.15-192.168.173.16-192.168.173.17-testvol-00-05
[1505999412.727592392] < 0 {"status": "Success", "message": "volserver=192.168.173.15 backup=192.168.173.16:192.168.173.17 volume=testvol mountpoint=/usr/libexec/kubernetes/kubelet-plugins/volume/exec/rht~glfs-subvol/mnt/192.168.173.15-testvol bindto=/var/lib/origin/openshift.local.volumes/pods/33a5af66-9ece-11e7-bbac-0cc47af70d00/volumes/rht~glfs-subvol/192.168.173.15-192.168.173.16-192.168.173.17-testvol-00-05"}
```

In the log file, each line begins with a timestamp, and the timestamp remains
constant for the length of the execution of the script. The purpose is to allow
multiple, overlapping invocations to be teased apart. The second (optional)
field is a single character.
* Lines with ">" are logs of the scripts invocation arguments.
* Lines with "<" are the script's output back to the driver.
* Lines with "!" are external command invocations made by the script.
* Lines without one of these characters are free-form diagnostic messages.

In the event that the logging generates too much output, it can be disabled by
setting `DEBUG` to `0`. However, when changing this value, be careful to update
the script in an atomic fashion if the node is currently in-use.
