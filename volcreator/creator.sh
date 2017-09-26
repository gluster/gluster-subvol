#! /bin/bash
# vim: set ts=4 sw=4 et :

function usage() {
    echo "Usage: $0 <server1:server2:...> <volume> <base_path> <quota_in_GB> <start> <end>"
    echo "    0 <= start <= end <= 65535"
}

function tohexpath() {
    local -i l1=$1/256
    local -i l2=$1%256
    printf '%02x/%02x' $l1 $l2
}

function mkPvTemplate() {
    local servers=$1
    local volume=$2
    local subdir=$3
    local capacity=$4

    local pv_name=$(echo "${servers}-${volume}-${subdir}" | tr ':/' '-')
    cat - << EOT
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: "$pv_name"
  labels:
    cluster: "$(echo $servers | tr ':' '-')"
    volume: "$volume"
    subdir: "$(echo $subdir | tr '/' '-')"
spec:
  capacity:
    storage: $capacity
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
#  storageClassName: $storage_class
  flexVolume:
    driver: "rht/glfs-subvol"
    options:
      cluster: $servers
      volume: $volume
      dir: $subdir
EOT
}



servers=$1
volume_name=$2
base_path=$3
volsize_gb=$4
declare -i i_start=$5
declare -i i_end=$6

declare -i i=$i_start

if [ $# -ne 6 ]; then usage; exit 1; fi
if [ $i -lt 0 ]; then usage; exit 1; fi
if [ $i -gt $i_end ]; then usage; exit 1; fi
if [ $i_end -gt 65535 ]; then usage; exit 1; fi

#-- Make sure quota is enabled on the volume
gluster volume quota $volume_name enable
#if [ $? != 0 ]; then
#    echo "Failed enabling quotas on the volume... continuing anyway."
#fi

#-- df on a directory should report remaining quota allowance,
#-- not volume free space.
gluster volume set $volume_name quota-deem-statfs on
if [ $? != 0 ]; then
    echo "Failed setting df space reporting volume option... continuing anyway."
fi

rm $base_path/pvs-$i_start-$i_end.yml
while [ $i -le $i_end ]; do
    subdir="$(tohexpath $i)"
    dir="$base_path/$subdir"
    echo "creating: $dir ($i/$i_end)"
    mkdir -p $dir
    if [ $? != 0 ]; then
        echo "Unable to create $dir"
        exit 2
    fi
    chmod 777 $dir
    if [ $? != 0 ]; then
        echo "Unable to set permissions on $dir"
        exit 2
    fi
    mkPvTemplate $servers $volume_name $subdir "${volsize_gb}Gi" >> $base_path/pvs-$i_start-$i_end.yml
    gluster volume quota $volume_name limit-usage /$subdir ${volsize_gb}GB
    if [ $? != 0 ]; then
        echo -n "Unable to set gluster quota. "
        echo "vol=$volume_name subdir=$subdir"
        exit 2
    fi
    ((++i))
done

exit 0
