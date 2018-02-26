# Subvol recycler

This directory contains the recycler that cleans out PVs once they are released
(the associated PersistentVolumeClaim is deleted), deletes all the files in the
underlying directory, recreated the block device and formats it as XFS and marks
the PV as ready to be used again.

## Overview

The recycler is run as a pod in the cluster, and it periodically searches for
PVs that:
* belong to a given Gluster cluster and volume
* are in the Released state

When the recycler script finds one or more PVs matching the above conditions, it
removes all files from the underlying subdirectory, then it patches the PV to
mark it Available.

TODO!!!