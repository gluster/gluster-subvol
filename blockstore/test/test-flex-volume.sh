#! /bin/bash

# See README.md under the parent directory of this script for details on how
# to run this.

# *** Globals to setup test environment ***
# SCRIPTDIR defines where the script will be copied and run from, this also
# decides where the gluster mount is going to appear in the system
# The gluster mount would appear under here,
#   - ${SCRIPTDIR}/${mntprefix}
SCRIPTDIR="/mnt/script-dir"

# PODSBASE defines the root directory under which the virtual pods are going
# to request mounts. This is where the loop device is mounted into.
# A typical request would be to mount a PVC under,
#   - ${PODSBASE}/${PODUID00}/${PODVOLUME}/${PODVOL1}
PODSBASE="/mnt/pods"

# *** Globals for easy reference to relative paths/mounts ***
PODUID00="00"
PODUID01="01"
PODVOLUME="volumes"
PODVOL1="vol1"
PODVOL2="vol2"

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

usage()
{
    echo "Usage: $0 <server1:server2:...> <volume>"
    echo "  - <server1:server2:...>: List of gluster server addresses."
    echo "      NOTE: If it is a single server setup repeat the address"
    echo "      twice, like so 192.168.121.10:192.168.121.10"
    echo "  - <volume>: Gluster volume name"
}

cleanup()
{
    rm -rf "${LOCKPATH}"
    if mountpoint -q "${SCRIPTDIR}/${mntprefix}/$(echo "$GLFS_CLUSTER_ADDR" | sed -r 's/^([^:]+):?(.*)/\1/')-${GLFS_VOLUME}"; then
        umount "${SCRIPTDIR}/${mntprefix}/$(echo "$GLFS_CLUSTER_ADDR" | sed -r 's/^([^:]+):?(.*)/\1/')-${GLFS_VOLUME}"
    fi
    rm -rf "${SCRIPTDIR}"
    # TODO: unmount loop devices first
    # rm -rf "${PODSBASE}"
}

setup()
{
    mkdir -p "${SCRIPTDIR}"
    cp ../flex-volume/glfs-block-subvol "${SCRIPTDIR}"
}

# *** Setup environment ***
if [ $# -ne 2 ]; then usage; exit 1; fi

GLFS_CLUSTER_ADDR="$1"
GLFS_VOLUME="$2"

ret=$(echo "${GLFS_CLUSTER_ADDR}" | grep -c ":")
if [ "$ret" -eq 0 ]; then usage; exit 1; fi

# TESTS START
cleanup;
setup;

# TEST 1
# Test init failure
#  - LOCKPATH is expected to be a directory, create a file instead!
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
# Test unmounting an non-existing mount
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
# Test a bad JSON request
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
# Test a valid unmount
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
# Test multiple mounts, and an unmount to ensure other mounts remain
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

# Check base gluster mount remains active
if ! mountpoint -q "${SCRIPTDIR}/${mntprefix}/$(echo "$GLFS_CLUSTER_ADDR" | sed -r 's/^([^:]+):?(.*)/\1/')-${GLFS_VOLUME}"; then
    echo "TEST 7: Did not find Gluster mount, here ${SCRIPTDIR}/${mntprefix}/$(echo "$GLFS_CLUSTER_ADDR" | sed -r 's/^([^:]+):?(.*)/\1/')-${GLFS_VOLUME}"
    exit 2
fi

# Check second mount is also remains active
if ! mountpoint -q "${PODSBASE}/${PODUID01}/${PODVOLUME}/${PODVOL2}"; then
    echo "TEST 7: Did not find pod mount, here ${PODSBASE}/${PODUID01}/${PODVOLUME}/${PODVOL2}"
    exit 2
fi

# Unmount the last
retjson=$("${SCRIPTDIR}"/glfs-block-subvol unmount "${PODSBASE}/${PODUID01}/${PODVOLUME}/${PODVOL2}")
status=$(echo "${retjson}" | jq -r .status)
if [ "${status}" != "${JSON_SUCCESS}" ]; then
    echo "TEST 7: Expected success from unmount"
    exit 2
fi
message=$(echo "${retjson}" | jq -r .message)
if [ "${message}" != "${JSON_UNMOUNT}${PODSBASE}/${PODUID01}/${PODVOLUME}/${PODVOL2}" ]; then
    echo "TEST 7: Expected message ${JSON_UNMOUNT}${PODSBASE}/${PODUID01}/${PODVOLUME}/${PODVOL2} from unmount, got ${message}"
    exit 2
fi

echo "TEST 7 passed"

exit 0
