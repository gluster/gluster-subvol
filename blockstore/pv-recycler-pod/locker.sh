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

# Grab a lock on the uuid file before running the recycler to try and ensure
# only one recycler runs against the volume at a time.
# Exit w/ code: 99 if we can't get the lock

f=/data/blockstore/supervol-uuid

echo Acquiring lock on $f
flock -x -n -E99 $f /recycler.sh $*
