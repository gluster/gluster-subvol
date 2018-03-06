# Creating sub-volume block device PVs

The script in this directory is used to pre-create files within a Gluster volume
that will be used as storage for PVs. The files are formatted as an XFS
filesystem and are used as block devices on the target nodes. The script is
designed to bulk-create the files as well as, generate a yaml file that can be
passed to `kubectl` to create the actual PV entries.

## Sub-volume structure

The script creates a higher level directory named `blockstore`, within the
provided Gluster volume, to separate the namespace within the Gluster volume.

The script uses a 2-level directory structure with each level having a two
hex-digit name, and within this directory creates a file with the 2 hex-digit
name. This permits up to 65536 total PVs to be created from a single
volume while also keeping individual file size manageable.

The script refers to these subdirs via a numeric index (0 - 65535) which is then
mapped to a directory name by converting to a 4-digit hex number and dividing
into path components. For example, index 20000 would be directory:
        20000 == 0x4e20 ==>/4e/20,
within which a (sparse) file named 4e20 would be created and formatted as an
XFS filesystem.

## Usage

The `creator.sh` script needs to be run from one of the Gluster server nodes
because it makes modifications to the underlying volume configuration using the
`gluster` command.

NOTE: As of now the script does not change any gluster configuration, but the
limitation is retained, as it may in the future (at which point this note
will be removed)

The following walkthrough will take an existing, empty Gluster volume named
`testvol` and pre-create 1000 files for use as PVs, with each designed
to hold 1GiB of data. The Gluster servers are 192.168.173.[15-17]

Start by mounting the volume on any server:
```sh
$ sudo mkdir /mnt/data
$ sudo mount -tglusterfs 192.168.173.15:/testvol /mnt/data
```

Run the creator script:
```sh
$ sudo ./creator.sh 192.168.173.15:192.168.173.16:192.168.173.17 testvol /mnt/data 1 0 999
```

The script will:
* Create a top level director named `blockstore`
* Create directories `/00/00` through `/03/e7` (via `/mnt/data/blockstore`)
* Create a sparse file of size 1GiB in each directory above named 0000 through 03e7
* Write the yaml PV description for the volumes into `/mnt/data/blockstore/pvs-0-999.yml`

The yaml file can then be applied to create the corresponding PVs:
```sh
$ kubectl apply -f pvs-0-999.yml
```

The Gluster volume may be unmounted:
```sh
$ sudo umount /mnt/data
$ sudo rmdir /mnt/data
```

## Note on gluster-block-subvol-sc.yml

This is a convinence file placed here. This is to be used in an Openshift or a
k8s environment, when it is desired that the gluster-block-subvol be made the
default storage class. To enable gluster-block-subvol to be the default stroage
class, assuming that the PVs are created use,
```sh
$ kubectl apply -f gluster-block-subvol-sc.yml
```
