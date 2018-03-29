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
    echo "Usage: $0 <brick_base_path> <quota.dat>"
}

function getMntPoint() {
    local orig="$1"
    local mntpt="$orig"
    while ! mountpoint -q "$mntpt"; do
        if [ ! -e "$mntpt" ]; then
            echo "NotFound"
            return
        fi
        mntpt="${mntpt}/.."
    done
    realpath "$mntpt"
}

function setQuota() {
    local projid="$1"
    local cap_gb="$2"
    local pathname="$3"
    local mp
    mp="$(getMntPoint "$3")"
    if [ -d "$mp" ] && [ "$mp" != "NotFound" ]; then
        #echo "Setting ${cap_gb}GB quota on $pathname as id $projid at mp: $mp"
        xfs_quota -x -c "project -s -p $pathname $projid" "$mp"
        xfs_quota -x -c "limit -p bhard=${cap_gb}g $projid" "$mp"
    else
        echo "mountpoint for $pathname not found"
        exit 1
    fi
}

base_path="$1"
quotafile="$2"

if [ $# -ne 2 ]; then usage; exit 1; fi

if [ ! -e "$quotafile" ]; then
    echo "Quota file not found: $quotafile"
    exit 2
fi

if [ ! -d "$base_path" ]; then
    echo "Brick base path not found: $base_path"
    exit 2
fi

while read -r projid cap_gb subdir || [ -n "$subdir" ]; do
    setQuota "$projid" "$cap_gb" "$base_path/$subdir"
done < "$quotafile"
