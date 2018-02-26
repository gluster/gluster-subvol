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
    echo "Usage: $0 <vol_root>"
}

sa_dir=/var/run/secrets/kubernetes.io/serviceaccount
kc_args="--server=https://kubernetes.default.svc.cluster.local --token=$(cat $sa_dir/token) --certificate-authority=$sa_dir/ca.crt"
blockstore_base="blockstore"

function create_blockdevice() {
    local blockfqpath="$1"
    local volsize_gb="$2"

    if ! touch "$blockfqpath"; then
        echo "Unable to create file ${blockfile}"
        return 2
    fi
    if ! chmod 777 "$blockfqpath"; then
        echo "Unable to set permissions on ${blockfile}"
        return 2
    fi
    # Create a sparse file of required volume size
    # 2097152 = 1024 * 1024 * 1024 (GB to bytes) / 512 (obs in dd)
    local seek_end
    seek_end=$((volsize_gb*2097152))
    if [ $? -eq 3 ]; then
        echo "Arithmetic error in expr, unable to setup ${blockfile}"
        return 2
    fi
    if ! dd seek="${seek_end}" obs=512 ibs=512 count=1 if=/dev/null of="${blockfqpath}" status=none ; then
        echo "Error in dd to ${blockfile}"
        return 2
    fi
    # Format the file with XFS
    if ! mkfs.xfs -q "${blockfqpath}"; then
        echo "mkfs.xfs failed for ${blockfqpath}"
        return 2
    fi
}

function recycle_pv() {
    local pv=$1

    # TODO: Possibly get .spec JSON once and derive all attrs from it, than call
    # kubectl multiple times.
    # Subdirectory checks
    local subdir
    if ! subdir=$(kubectl "$kc_args" get pv/"$pv" \
        -ojsonpath='{.spec.flexVolume.options.dir}'); then
        echo "Failed parsing PV $pv (unable to get backing dir)"
        return
    fi
    # make sure subdir is non-empty
    if [ "x$subdir" == "x" ]; then
        echo "Couldn't determine subdirectory for $pv"
        return
    fi
    # make sure subdir doesn't contain ..
    echo "$subdir" | grep -q '\.\.'
    if [ $? -ne 1 ]; then
        echo "Found .. in subdir for $pv"
        return
    fi

    # File checks
    local blockfile
    if blockfile=$(kubectl "$kc_args" get pv/"$pv" \
        -ojsonpath='{.spec.flexVolume.options.file}'); then
        echo "Failed parsing PV $pv (unable to get backing file)"
        return
    fi
    # make sure blockfile is non-empty
    if [ "x$blockfile" == "x" ]; then
        echo "Couldn't determine backing file for $pv with subdir $subdir"
        return
    fi

    # Size checks
    local capacity_str
    if capacity_str=$(kubectl "$kc_args" get pv/"$pv" \
        -ojsonpath='{.spec.capacity.storage}'); then
        echo "Failed parsing PV $pv (unable to get backing file capacity)"
        return
    fi
    capacity=$(echo "$capacity_str" | sed -r "s/Gi//")
    if [ "x$capacity" == "x" ]; then
        echo "Couldn't determine capacity for file $blockfile in $pv with subdir $subdir"
        return
    fi

    local scrub="${vol_root}/${subdir}/${blockfile}"
    echo "= $(date) = Working on ${pv}"
    echo "  Scrubbing $scrub"
    test -e "$scrub" && rm -f "$scrub" && test -z "$(ls -A "${vol_root}/${subdir}")"
    if [ $? -ne 0 ]; then
        echo "  $(date) = Scrubbing failed. Not freeing $pv... will retry later."
        return
    fi
    if ! create_blockdevice "$scrub" "$capacity"; then
        echo "Failed recreating block device. Not freeing $pv... will retry later"
        return
    fi
    echo "  $(date) = Scrubbing successful. Marking $pv as available."

    # Mark it available
    kubectl "$kc_args" patch pv/"$pv" --type json -p'[{"op":"remove", "path":"/spec/claimRef"}, {"op":"replace", "path":"/status/phase", "value":"Available"}]'
}

function recycle_all() {
    pvs=$(kubectl "$kc_args" get pv \
        -l supervol="$uuid" \
        -ojsonpath='{range .items[*]}{.metadata.name} {.status.phase}{"\n"}{end}' \
        | grep Released | cut -f1 -d' ')
    for pv in $pvs; do
        recycle_pv "$pv"
    done
}

if [ $# -ne 1 ]; then usage; exit 1; fi

vol_root="$1/${blockstore_base}"

if [ ! -f "${vol_root}/supervol-uuid" ]; then
    echo "Unable to read UUID from volume (${vol_root}/supervol-uuid)"
    exit 1;
fi
uuid=$(cat "${vol_root}/supervol-uuid")

echo "Recycling block devices for supervol: $uuid"

while true; do
    recycle_all
    sleep 10
done
