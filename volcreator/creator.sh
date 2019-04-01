#! /bin/bash
# vim: set ts=4 sw=4 et :

# Copyright 2018 Red Hat, Inc. and/or its affiliates.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
    local uuid=$5

    local pv_name=$(echo "${uuid}-${subdir}" | tr '/' '-')
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
    supervol: "$uuid"
spec:
  capacity:
    storage: $capacity
  accessModes:
    - ReadWriteOnce
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: gluster-subvol
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

if [ ! -f $base_path/supervol-uuid ]; then
    uuidgen -r > $base_path/supervol-uuid
fi
supervol_uuid=$(cat $base_path/supervol-uuid)

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
    mkPvTemplate $servers $volume_name $subdir "${volsize_gb}Gi" $supervol_uuid >> $base_path/pvs-$i_start-$i_end.yml
    gluster volume quota $volume_name limit-usage /$subdir ${volsize_gb}GB
    if [ $? != 0 ]; then
        echo -n "Unable to set gluster quota. "
        echo "vol=$volume_name subdir=$subdir"
        exit 2
    fi
    ((++i))
done

exit 0
