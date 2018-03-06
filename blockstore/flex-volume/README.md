# Installation of flex volume plugin

This is a flex volume plugin that needs to be installed on each Kubernetes node.
Included in this directory is an ansible playbook (`install_plugin.yml`) that
performs the install. This playbook:
* Creates the directory for the plugin:
`/usr/libexec/kubernetes/kubelet-plugins/volume/exec/rht~glfs-block-subvol`
* Copies both the plugin script `glfs-block-subvol` to that directory.

Upon first install, it may be necessary to restart kubelet for it to find the
plugin.

# Usage
To use the plugin, include the following as a volume description.
```yaml
  flexVolume:
    driver: "rht/glfs-block-subvol"
    options:
      cluster: 192.168.173.15:192.168.173.16:192.168.173.17
      volume: "testvol"
      dir: "00/01"
      file: "0001"
```
The required options for the driver are:
* `cluster`: A colon separated list of the Gluster nodes in the cluster. The
first will be used as the primary for mounting, and the rest will be listed as
backup volume servers.
* `volume`: This is the name of the large Gluster volume that is being
subdivided.
* `dir`: This is the path from the root of the volume to the subdirectory which
will contain the file that would be loop mounted to be the volume.
* `file`: This is the name of the file within `dir` that is loop mounted as an
XFS file system as the volume for the claim.

The above example would use 192.168.173.15:/testvol/00/01/0001 to hold the PV
contents.

# Diagnostics/debugging
The `glfs-block-subvol` script has logging for all of its actions to help
diagnose problems with the plugin. The logging settings are at the top of the
script file:
```sh
# if DEBUG, log everything to a file as we do it
DEBUG=1
DEBUGFILE='/tmp/glfs-block-subvol.out'
```
When `DEBUG` is `1`, all calls and actions taken by the plugin are logged to
`DEBUGFILE`. The following is an example of the log file:
```
[1520361740.373690279] > init
[1520361740.373690279] < 0 {"status": "Success", "capabilities": {"attach": false, "selinuxRelabel": false}}
[1520361740.405577771] > mount /mnt/pods/00/volumes/vol1 {"cluster":"127.0.0.1:127.0.0.1","dir":"blockstore/00/00","volume":"patchy","file":"0000"}
[1520361740.405577771] volserver 127.0.0.1
[1520361740.405577771] backupservers 127.0.0.1
[1520361740.405577771] Using lockfile: /var/lock/glfs-block-subvol/127.0.0.1-patchy.lock
[1520361740.405577771] ! mount -t glusterfs -o backup-volfile-servers=127.0.0.1 127.0.0.1:/patchy /mnt/script-dir/mnt/blockstore/127.0.0.1-patchy
[1520361740.405577771] ! mount /mnt/script-dir/mnt/blockstore/127.0.0.1-patchy/blockstore/00/00/0000 /mnt/pods/00/volumes/vol1 -t xfs -o loop,discard
[1520361740.405577771] < 0 {"status": "Success", "message": "volserver=127.0.0.1 backup=127.0.0.1 volume=patchy mountpoint=/mnt/script-dir/mnt/blockstore/127.0.0.1-patchy bindto=/mnt/pods/00/volumes/vol1"}
[1520361740.849832326] > unmount /mnt/pods/00/volumes/vol1
[1520361740.849832326] ldevice=/dev/loop0
[1520361740.849832326] ldevicefile=/mnt/script-dir/mnt/blockstore/127.0.0.1-patchy/blockstore/00/00/0000
[1520361740.849832326] gdevicedir=/mnt/script-dir/mnt/blockstore/127.0.0.1-patchy
[1520361740.849832326] mntsuffix=127.0.0.1-patchy
[1520361740.849832326] ! umount /mnt/pods/00/volumes/vol1
[1520361740.849832326] Using lockfile: /var/lock/glfs-block-subvol/127.0.0.1-patchy.lock
[1520361740.849832326] /mnt/script-dir/mnt/blockstore/127.0.0.1-patchy has 0 loop mounted files
[1520361740.849832326] We were last user of /mnt/script-dir/mnt/blockstore/127.0.0.1-patchy; unmounting it.
[1520361740.849832326] ! umount /mnt/script-dir/mnt/blockstore/127.0.0.1-patchy
[1520361740.849832326] ! rmdir /mnt/script-dir/mnt/blockstore/127.0.0.1-patchy
[1520361740.849832326] < 0 {"status": "Success", "message": "Unmounting from /mnt/pods/00/volumes/vol1"}
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
