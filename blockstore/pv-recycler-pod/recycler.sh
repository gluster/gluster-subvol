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
kc_args=("--server=https://kubernetes.default.svc.cluster.local" "--token=$(cat $sa_dir/token)" "--certificate-authority=$sa_dir/ca.crt")
blockstore_base="blockstore"

function create_blockdevice() {
    local blockfqpath="$1"
    local volsize_gb="$2"

    if ! touch "$blockfqpath"; then
        echo "Unable to create file ${blockfile}"
        return 2
    fi
    # Create a sparse file of required volume size
    if ! dd bs=1 count=1 if=/dev/zero of="${blockfqpath}" seek="$((volsize_gb * 1024 * 1024 *1024))" status=none; then
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
    if ! subdir=$(kubectl "${kc_args[@]}" get pv/"$pv" \
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
    if ! blockfile=$(kubectl "${kc_args[@]}" get pv/"$pv" \
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
    if ! capacity_str=$(kubectl "${kc_args[@]}" get pv/"$pv" \
        -ojsonpath='{.spec.capacity.storage}'); then
        echo "Failed parsing PV $pv (unable to get backing file capacity)"
        return
    fi
    # TODO: Current assumption is capacity is always in Gi units
    capacity=$(echo "$capacity_str" | sed -r "s/Gi//")
    if [ "x$capacity" == "x" ]; then
        echo "Couldn't determine capacity for file $blockfile in $pv with subdir $subdir"
        return
    fi

    local scrub="${vol_root}/${subdir}/${blockfile}"
    echo "= $(date) = Working on ${pv}"
    echo "  Scrubbing $scrub"
    if ! rm -f "$scrub"; then
        echo "  $(date) = Scrubbing failed. Not freeing $pv... will retry later."
        return
    fi
    if ! create_blockdevice "$scrub" "$capacity"; then
        echo "Failed recreating block device. Not freeing $pv... will retry later"
        return
    fi
    echo "  $(date) = Scrubbing successful. Marking $pv as available."

    # Mark it available
    kubectl "${kc_args[@]}" patch pv/"$pv" --type json -p'[{"op":"remove", "path":"/spec/claimRef"}, {"op":"replace", "path":"/status/phase", "value":"Available"}]'
}

function recycle_all() {
    # TODO: Check and determine how to request bounded list of entries, rather
    # than potentially overflowing the contents of the pvs variable. There seems
    # to be a --chunk-size option, but that still returns all in current
    # experiments.
    pvs=$(kubectl "${kc_args[@]}" get pv \
        -l supervol="$uuid" \
        -ojsonpath='{range .items[*]}{.metadata.name} {.status.phase}{"\n"}{end}' \
        | grep Released | cut -f1 -d' ')
    for pv in $pvs; do
        recycle_pv "$pv"
    done
}

if [ $# -ne 1 ]; then usage; exit 1; fi

vol_root="$1"

if [ ! -f "${vol_root}/${blockstore_base}/supervol-uuid" ]; then
    echo "Unable to read UUID from volume (${vol_root}/${blockstore_base}/supervol-uuid)"
    exit 1;
fi
uuid=$(cat "${vol_root}/${blockstore_base}/supervol-uuid")

echo "Recycling block devices for supervol: $uuid"

while true; do
    recycle_all
    sleep 10
done
