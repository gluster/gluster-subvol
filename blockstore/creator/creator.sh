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

blockstore_base="blockstore"

function usage() {
    echo "Usage: $0 <server1:server2:...> <volume> <base_path> <quota_in_GB> <start> <end>"
    echo "    0 <= start <= end <= 65535"
}

function tohexpath() {
    local -i l1=$1/256
    local -i l2=$1%256
    printf '%02x/%02x' "$l1" "$l2"
}

function tohexname() {
    local -i l1=$1/256
    local -i l2=$1%256
    printf '%02x%02x' "$l1" "$l2"
}

function mkPvTemplate() {
    local servers=$1
    local volume=$2
    local subdir=$3
    local blockfile=$4
    local capacity=$5
    local uuid=$6

    local pv_name
    pv_name=$(echo "gluster-block-${uuid}-${subdir}-${blockfile}" | tr '/' '-')
    cat - << EOT
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: "$pv_name"
  labels:
    cluster: "$(echo "$servers" | tr ':' '-')"
    volume: "$volume"
    subdir: "$(echo "${blockstore_base}/${subdir}" | tr '/' '-')"
    supervol: "$uuid"
spec:
  capacity:
    storage: $capacity
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: gluster-block-subvol
  flexVolume:
    driver: "rht/glfs-block-subvol"
    options:
      cluster: "$servers"
      volume: "$volume"
      dir: "${blockstore_base}/${subdir}"
      file: "$blockfile"
EOT
}


servers=$1
volume_name=$2
base_path_in=$3
volsize_gb=$4
declare -i i_start=$5
declare -i i_end=$6

declare -i i=$i_start

if [ $# -ne 6 ]; then usage; exit 1; fi
if [ "$i" -lt 0 ]; then usage; exit 1; fi
if [ "$i" -gt "$i_end" ]; then usage; exit 1; fi
if [ "$i_end" -gt 65535 ]; then usage; exit 1; fi

base_path="${base_path_in}/${blockstore_base}"
if [ ! -d "${base_path}" ]; then
    if ! mkdir "${base_path}"; then
        echo "Unable to create $base_path"
        exit 2
    fi
fi

if [ ! -f "${base_path}/supervol-uuid" ]; then
    uuidgen -r > "${base_path}/supervol-uuid"
fi
supervol_uuid=$(cat "${base_path}/supervol-uuid")

if [ -f "${base_path}/pvs-${i_start}-${i_end}.yml" ]; then
    rm "${base_path}/pvs-${i_start}-${i_end}.yml"
fi

while [ "$i" -le "$i_end" ]; do
    subdir=$(tohexpath "$i")
    dir="${base_path}/${subdir}"
    echo "creating: ${dir} (${i}/${i_end})"
    if ! mkdir -p "$dir"; then
        echo "Unable to create $dir"
        exit 2
    fi
    blockfile=$(tohexname "$i")
    blockfqpath="${base_path}/${subdir}/${blockfile}"
    # File should not exist, or do not mess up existing devices here!
    if [ -f "$blockfqpath" ]; then
        echo "Found an existing device file with at $blockfile; skipping device creation"
        ((++i))
        continue
    fi
    if ! touch "$blockfqpath"; then
        echo "Unable to create file ${blockfile}"
        exit 2
    fi
    # Create a sparse file of required volume size
    if ! dd bs=1 count=1 if=/dev/zero of="${blockfqpath}" seek="$((volsize_gb * 1024 * 1024 *1024))" status=none; then
        echo "Error in dd to ${blockfile}"
        exit 2
    fi
    # Format the file with XFS
    if ! mkfs.xfs -q "${blockfqpath}"; then
        echo "mkfs.xfs failed for ${blockfqpath}"
        exit 2
    fi
    # TODO: Check mount (?)
    # TODO: mkPvTemplate is as is, may need modifications
    mkPvTemplate "$servers" "$volume_name" "$subdir" "$blockfile" "${volsize_gb}Gi" "$supervol_uuid" >> "${base_path}/pvs-${i_start}-${i_end}.yml"
    ((++i))
done

exit 0
