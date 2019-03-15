#! /bin/bash

set -e -opipefail

FLEXVOL_PLUGIN_PATH=/flexpath

# Copies a source file to a destination, ensuring an atomic overwrite of an old
# file (if present). It also ensures the temporary file begins w/ a dot to
# ensure it doesn't get picked up by the plugin autodiscovery mechanism. See:
# https://github.com/kubernetes/community/blob/master/contributors/design-proposals/storage/flexvolume-deployment.md#detailed-design
function safe_copy {
        SRC="$1"
        DST_DIR="$2"

        FNAME="$(basename "${SRC}")"

        cp -av "$SRC" "${DST_DIR}/.${FNAME}"
        mv -fv "${DST_DIR}/.${FNAME}" "${DST_DIR}/${FNAME}"
}

PLUGINDIR="${FLEXVOL_PLUGIN_PATH}/rht~glfs-subvol"
mkdir -p "${PLUGINDIR}"
mkdir -p "${PLUGINDIR}/.bin"
safe_copy /usr/bin/jq "${PLUGINDIR}/.bin/"
safe_copy /glfs-subvol "${PLUGINDIR}/"

while true; do
        sleep 3600
done
