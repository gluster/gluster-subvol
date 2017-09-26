# Creating sub-volume PVs

The script in this directory is used to pre-create directories within a Gluster
volume that will be used as storage for PVs. The script is designed to
bulk-create the directories as well as yaml files that can be passed to
`kubectl` to create the actual PV entries.

## Sub-volume structure

The script uses a 2-level directory structure with each level having a two
hex-digit name. This permits up to 65536 total PVs to be created from a single
volume while also keeping individual directory size manageable. The script
refers to these subdirs via a numeric index (0 - 65535) which is then mapped to
a directory name by converting to a 4-digit hex number and dividing into path
components. For example, index 20000 would be directory: 20000 == 0x4e20 ==>
/4e/20.

## Usage

The `creator.sh` script needs to be run from one of the Gluster server nodes
because it makes modifications to the underlying volume configuration using the
`gluster` command.

The following walkthrough will take an existing, empty Gluster volume named
`testvol` and pre-create 1000 subdirectories for use as PVs, with each designed
to hold 1GiB of data. The Gluster servers are 192.168.173.[15-17]

Start by mounting the volume on the server:
```sh
$ sudo mkdir /mnt/data
$ sudo mount -tglusterfs 192.168.173.15:/testvol /mnt/data
```

Run the creator script:
```sh
$ sudo ./creator.sh 192.168.173.15:192.168.173.16:192.168.173.17 testvol /mnt/data 1 0 999
```

The script will:
* Create directories `/00/00` through `/03/e7` (via `/mnt/data/`)
* Set quotas of 1GB on each of those directories
* Write the yaml PV description for the volumes into `/mnt/data/pvs-0-999.yml`

The yaml file can then be applied to create the corresponding PVs:
```sh
$ kubectl apply -f pvs-0-999.yml
```

The Gluster volume may be unmounted:
```sh
$ sudo umount /mnt/data
$ sudo rmdir /mnt/data
```
