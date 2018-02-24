#! /bin/bash

# TODO: Write a how to execute!!!

# Globals to setup test environment
SCRIPTDIR="/mnt/script-dir"
PODSBASE="/mnt/pods"
GLFS_CLUSTER_ADDR="127.0.0.1:127.0.0.1" # <addr>:<addr>:... as it suits the setup
GLFS_VOLUME="patchy"

# Globals for easy reference to relative paths/mounts
PODUID00="00"
PODUID01="01"
PODUID02="02"
PODUID03="03"
PODVOLUME="volumes"
PODVOL1="vol1"
PODVOL2="vol2"
PODVOL3="vol3"

# Static(s) from the glfs-block-subvol script
mntprefix="mnt/blockstore"
LOCKPATH="/var/lock/glfs-block-subvol"

# JSON messages from glfs-block-subvol script
JSON_SUCCESS="Success"
JSON_FAILURE="Failure"
JSON_NOMOUNT="Was not mounted."
JSON_UNMOUNT="Unmounting from "

# Hacks!
# 1. Testing on a local setup, hence do not have multiple Gluster ADDRs, hence faking the same address twice

cleanup()
{
    rm -rf "${LOCKPATH}"
    # TODO: unmount first
    rm -rf "${SCRIPTDIR}"
    # TODO: unmount loop devices first
    # rm -rf "${PODSBASE}"
}

setup()
{
    mkdir -p "${SCRIPTDIR}"
    cp ../flex-volume/glfs-block-subvol "${SCRIPTDIR}"
}

# TESTS START
cleanup;
setup;

# TEST 1
# Test init failure
touch $LOCKPATH
retjson=$("${SCRIPTDIR}"/glfs-block-subvol init)
status=$(echo "${retjson}" | jq -r .status)
if [ "${status}" != "${JSON_FAILURE}" ]; then
    echo "TEST1: Expected failure from init"
    exit 2
fi

echo "TEST 1 passed"

cleanup;
setup;

# TEST 2
# Test init passing
retjson=$("${SCRIPTDIR}"/glfs-block-subvol init)
status=$(echo "${retjson}" | jq -r .status)
if [ "${status}" != "${JSON_SUCCESS}" ]; then
    echo "TEST2: Expected success from init"
    exit 2
fi

if [ ! -d "${SCRIPTDIR}/${mntprefix}" ]; then
    echo "TEST2: Directory missing: ${SCRIPTDIR}/${mntprefix}"
    exit 2
fi

if [ ! -d ${LOCKPATH} ]; then
    echo "TEST2; Directory missing: ${LOCKPATH}"
    exit 2
fi

echo "TEST 2 passed"

cleanup;
setup;

# TEST 3
# Fail an non-existing mount
retjson=$("${SCRIPTDIR}"/glfs-block-subvol init)
status=$(echo "${retjson}" | jq -r .status)
if [ "${status}" != "${JSON_SUCCESS}" ]; then
    echo "TEST3: Expected success from init"
    exit 2
fi

retjson=$("${SCRIPTDIR}"/glfs-block-subvol unmount "${PODSBASE}/${PODUID00}/${PODVOLUME}/${PODVOL1}")
status=$(echo "${retjson}" | jq -r .status)
if [ "${status}" != "${JSON_SUCCESS}" ]; then
    echo "TEST 3: Expected success from unmount"
    exit 2
fi
message=$(echo "${retjson}" | jq -r .message)
if [ "${message}" != "${JSON_NOMOUNT}" ]; then
    echo "TEST 3: Expected message ${JSON_NOMOUNT} from unmount, got ${message}"
    exit 2
fi

echo "TEST 3 passed"

# TEST 4
# Test a bad JSON
mount_json="{\"bcluster\":\"${GLFS_CLUSTER_ADDR}\",\"dir\":\"blockstore/00/00\",\"volume\":\"${GLFS_VOLUME}\",\"file\":\"0000\"}"
retjson=$("${SCRIPTDIR}"/glfs-block-subvol mount "${PODSBASE}/${PODUID00}/${PODVOLUME}/${PODVOL1}" "${mount_json}")
status=$(echo "${retjson}" | jq -r .status)
if [ "${status}" != "${JSON_FAILURE}" ]; then
    echo "TEST 4: Expected failure from mount"
    exit 2
fi
message=$(echo "${retjson}" | jq -r .message)

echo "TEST 4 passed"

# TODO:test non-existent dir/file values, test single cluster addr in list

# TEST 5
# Test a valid mount
mkdir -p "${PODSBASE}/${PODUID00}/${PODVOLUME}/${PODVOL1}"
mount_json="{\"cluster\":\"${GLFS_CLUSTER_ADDR}\",\"dir\":\"blockstore/00/00\",\"volume\":\"${GLFS_VOLUME}\",\"file\":\"0000\"}"
retjson=$("${SCRIPTDIR}"/glfs-block-subvol mount "${PODSBASE}/${PODUID00}/${PODVOLUME}/${PODVOL1}" "${mount_json}")
status=$(echo "${retjson}" | jq -r .status)
if [ "${status}" != "${JSON_SUCCESS}" ]; then
    echo "TEST 5: Expected success from mount"
    exit 2
fi

if ! mountpoint -q "${PODSBASE}/${PODUID00}/${PODVOLUME}/${PODVOL1}"; then
    echo "TEST 5: Did not find pod mount, here ${PODSBASE}/${PODUID00}/${PODVOLUME}/${PODVOL1}"
    exit 2
fi

echo "TEST 5 passed"

# TEST 6
# test a valid unmount
retjson=$("${SCRIPTDIR}"/glfs-block-subvol unmount "${PODSBASE}/${PODUID00}/${PODVOLUME}/${PODVOL1}")
status=$(echo "${retjson}" | jq -r .status)
if [ "${status}" != "${JSON_SUCCESS}" ]; then
    echo "TEST 6: Expected success from unmount"
    exit 2
fi
message=$(echo "${retjson}" | jq -r .message)
if [ "${message}" != "${JSON_UNMOUNT}${PODSBASE}/${PODUID00}/${PODVOLUME}/${PODVOL1}" ]; then
    echo "TEST 6: Expected message ${JSON_UNMOUNT}${PODSBASE}/${PODUID00}/${PODVOLUME}/${PODVOL1} from unmount, got ${message}"
    exit 2
fi

if mountpoint -q "${SCRIPTDIR}/${mntprefix}/$(echo "$GLFS_CLUSTER_ADDR" | sed -r 's/^([^:]+):?(.*)/\1/')-${GLFS_VOLUME}"; then
    echo "TEST 6: Found Gluster mount still existing, here ${SCRIPTDIR}/${mntprefix}/$(echo "$GLFS_CLUSTER_ADDR" | sed -r 's/^([^:]+):?(.*)/\1/')-${GLFS_VOLUME}"
    exit 2
fi

echo "TEST 6 passed"

# TEST 7
# Test a multiple mounts, and an unmount to ensure other mounts remain
# First mount
mkdir -p "${PODSBASE}/${PODUID00}/${PODVOLUME}/${PODVOL1}"
mount_json="{\"cluster\":\"${GLFS_CLUSTER_ADDR}\",\"dir\":\"blockstore/00/00\",\"volume\":\"${GLFS_VOLUME}\",\"file\":\"0000\"}"
retjson=$("${SCRIPTDIR}"/glfs-block-subvol mount "${PODSBASE}/${PODUID00}/${PODVOLUME}/${PODVOL1}" "${mount_json}")
status=$(echo "${retjson}" | jq -r .status)
if [ "${status}" != "${JSON_SUCCESS}" ]; then
    echo "TEST 7: Expected success from mount"
    exit 2
fi

if ! mountpoint -q "${PODSBASE}/${PODUID00}/${PODVOLUME}/${PODVOL1}"; then
    echo "TEST 7: Did not find pod mount, here ${PODSBASE}/${PODUID00}/${PODVOLUME}/${PODVOL1}"
    exit 2
fi

# Second mount
mkdir -p "${PODSBASE}/${PODUID01}/${PODVOLUME}/${PODVOL2}"
mount_json="{\"cluster\":\"${GLFS_CLUSTER_ADDR}\",\"dir\":\"blockstore/00/01\",\"volume\":\"${GLFS_VOLUME}\",\"file\":\"0001\"}"
retjson=$("${SCRIPTDIR}"/glfs-block-subvol mount "${PODSBASE}/${PODUID01}/${PODVOLUME}/${PODVOL2}" "${mount_json}")
status=$(echo "${retjson}" | jq -r .status)
if [ "${status}" != "${JSON_SUCCESS}" ]; then
    echo "TEST 7: Expected success from mount"
    exit 2
fi

if ! mountpoint -q "${PODSBASE}/${PODUID01}/${PODVOLUME}/${PODVOL2}"; then
    echo "TEST 7: Did not find pod mount, here ${PODSBASE}/${PODUID01}/${PODVOLUME}/${PODVOL2}"
    exit 2
fi

# Unmount one
retjson=$("${SCRIPTDIR}"/glfs-block-subvol unmount "${PODSBASE}/${PODUID00}/${PODVOLUME}/${PODVOL1}")
status=$(echo "${retjson}" | jq -r .status)
if [ "${status}" != "${JSON_SUCCESS}" ]; then
    echo "TEST 7: Expected success from unmount"
    exit 2
fi
message=$(echo "${retjson}" | jq -r .message)
if [ "${message}" != "${JSON_UNMOUNT}${PODSBASE}/${PODUID00}/${PODVOLUME}/${PODVOL1}" ]; then
    echo "TEST 7: Expected message ${JSON_UNMOUNT}${PODSBASE}/${PODUID00}/${PODVOLUME}/${PODVOL1} from unmount, got ${message}"
    exit 2
fi

if ! mountpoint -q "${SCRIPTDIR}/${mntprefix}/$(echo "$GLFS_CLUSTER_ADDR" | sed -r 's/^([^:]+):?(.*)/\1/')-${GLFS_VOLUME}"; then
    echo "TEST 7: Did not find Gluster mount, here ${SCRIPTDIR}/${mntprefix}/$(echo "$GLFS_CLUSTER_ADDR" | sed -r 's/^([^:]+):?(.*)/\1/')-${GLFS_VOLUME}"
    exit 2
fi

if ! mountpoint -q "${PODSBASE}/${PODUID01}/${PODVOLUME}/${PODVOL2}"; then
    echo "TEST 7: Did not find pod mount, here ${PODSBASE}/${PODUID01}/${PODVOLUME}/${PODVOL2}"
    exit 2
fi

echo "TEST 7 passed"

exit 0
