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
    printf '%02x/%02x' "$l1" "$l2"
}

function mkPvTemplate() {
    local servers=$1
    local volume=$2
    local subdir=$3
    local capacity=$4
    local uuid=$5

    local pv_name
    pv_name=$(echo "${uuid}-${subdir}" | tr '/' '-')
    cat - << EOT
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: "$pv_name"
  labels:
    cluster: "$(echo "$servers" | tr ':' '-')"
    volume: "$volume"
    subdir: "$(echo "$subdir" | tr '/' '-')"
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

function mkQuotaCmd() {
    local dir_idx=$1
    local cap_gb=$2
    # Since projid=0 is special in xfs, we add an offset of 100000 to the
    # subdir index. Since we don't expect > 100000 quotas/subvols, this
    # allows easy conversion by looking at the lower digits.
    # Format for the file is 1 quota per line:
    # projid cap_gb subdir
    local projid=$((dir_idx + 100000))
    local subdir
    subdir="$(tohexpath "$i")"
    echo "$projid $cap_gb $subdir"
}



servers=$1
volume_name=$2
base_path=$3
volsize_gb=$4
declare -i i_start=$5
declare -i i_end=$6

declare -i i=$i_start

if [ $# -ne 6 ]; then usage; exit 1; fi
if [ "$i" -lt 0 ]; then usage; exit 1; fi
if [ "$i" -gt "$i_end" ]; then usage; exit 1; fi
if [ "$i_end" -gt 65535 ]; then usage; exit 1; fi

if [ ! -f "$base_path/supervol-uuid" ]; then
    uuidgen -r > "$base_path/supervol-uuid"
fi
supervol_uuid=$(cat "$base_path/supervol-uuid")

rm "$base_path/pvs-$i_start-$i_end.yml"
while [ "$i" -le "$i_end" ]; do
    subdir="$(tohexpath "$i")"
    dir="$base_path/$subdir"
    echo "creating: $dir ($i/$i_end)"
    if ! mkdir -p "$dir"; then
        echo "Unable to create $dir"
        exit 2
    fi
    if ! chmod 777 "$dir"; then
        echo "Unable to set permissions on $dir"
        exit 2
    fi
    mkPvTemplate "$servers" "$volume_name" "$subdir" "${volsize_gb}Gi" "$supervol_uuid" >> "$base_path/pvs-$i_start-$i_end.yml"
    mkQuotaCmd "$i" "$volsize_gb" >> "$base_path/quota-$i_start-$i_end.dat"
    ((++i))
done

exit 0
