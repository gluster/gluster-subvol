#! /bin/bash

set -e -opipefail

FLEXVOL_PLUGIN_PATH=${FLEXVOL_PLUGIN_PATH-/usr/libexec/kubernetes/kubelet-plugins/volume/exec}

# Copies a source file to a destination, ensuring an atomic overwrite of an old
# file (if present).
function safe_copy {
        SRC="$1"
        DST="$2"

        cp -av "$SRC" "${DST}.new"
        mv -v "${DST}.new" "${DST}"
}

PLUGINDIR="${FLEXVOL_PLUGIN_PATH}/rht~glfs-subvol"
mkdir -p "${PLUGINDIR}"
mkdir -p "${PLUGINDIR}/.bin"
safe_copy /usr/bin/jq "${PLUGINDIR}/.bin/jq"
safe_copy /glfs-subvol "${PLUGINDIR}/glfs-subvol"
