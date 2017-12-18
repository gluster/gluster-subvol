#! /bin/bash
# vim: set ts=4 sw=4 et :

# Grab a lock on the uuid file before running the recycler to try and ensure
# only one recycler runs against the volume at a time.
# Exit w/ code: 99 if we can't get the lock

f=/data/supervol-uuid

echo Acquiring lock on $f
flock -x -n -E99 $f /recycler.sh $*
