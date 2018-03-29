# Using XFS project quotas instead of Gluster quotas

Gluster's implementation of quotas tends to have high overhead for small-file
workloads. In cases where straight replication is being used (no disperse), each
brick will have the same view of a directory, and xfs quotas can be used at the
brick level to constrain subdir space usage.

The `creator_xfs_quota.sh` and `apply_xfs_quota.sh` scripts can be used to set
up the subdir volumes in the same way as `creator.sh` is used to set up with
Gluster quota.

## Creating the subdirectories

The `creator_xfs_quota.sh` script is used to create the subdirectories in the
supervol, build the PV yaml file, and create a file that describes the xfs
project quotas that need to be applied to the Gluster bricks.

1. Mount the supervol
   ```sh
   $ mkdir /mnt/supervol00
   $ mount -t glusterfs localhost:/supervol00 /mnt/supervol00
   ```
1. Create the subdirs. The following example is creating 5000 subvol PVs (0 --
   4999).
   ```sh
   $ ./creator_xfs_quota.sh 172.31.80.251:172.31.87.134:172.31.93.163 supervol00 /mnt/supervol00/ 1 0 4999
   ```

The above steps will create the `pvs-0-4999.yml` containing the PV descriptions,
and an additional file, `quota-0-4999.dat` that contains the quota information.

## Applying the quotas

The quotas need to be applied to each backing brick. Perform the following
command on each brick:

1. Copy or mount the quota dat file on each server.
1. Apply the quotas, providing the root directory of the brick and the path to
   the quota file
   ```sh
   $ ./apply_xfs_quota.sh /bricks/supervol00/brick /mnt/supervol00/quota-0-4999.dat
   ```

## Viewing quotas and usage

The usage can be checked by logging into a server and running:
```sh
$ sudo xfs_quota -x -c 'report -p -a'
Project quota on /bricks/supervol00 (/dev/mapper/supervol00-supervol00)
                               Blocks
Project ID       Used       Soft       Hard    Warn/Grace
---------- --------------------------------------------------
#0               9900          0          0     00 [--------]
#100000        102400          0    1048576     00 [--------]
#100001             0          0    1048576     00 [--------]
#100002             0          0    1048576     00 [--------]
#100003             0          0    1048576     00 [--------]
#100004             0          0    1048576     00 [--------]
...
```

The project id numbers correspond to the subdir indicies: Directory 0 maps to
`00/00` which corresponds to project id 100000.

In the above example, we see that `00/00` has used 100 MB of the 1 GB quota.
Project id 0 is the default project and should be ignored.
