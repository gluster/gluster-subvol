#! /bin/bash

set -e -o pipefail

# Volumes that need to be mapped
FLEXVOL_PLUGIN_PATH=/flexpath
HOST_ETCSSL=/etcssl
TLS_SECRET_PATH=/tlskeys
VAR_LIB_GLUSTERD=/glusterd


TLS_NODE_KEY="${HOST_ETCSSL}"/glusterfs.key
TLS_NODE_CSR="${HOST_ETCSSL}"/glusterfs.csr
TLS_NODE_PEM="${HOST_ETCSSL}"/glusterfs.pem
TLS_CA="${HOST_ETCSSL}"/glusterfs.ca
CA_KEY="${TLS_SECRET_PATH}/ca.key"
CA_PEM="${TLS_SECRET_PATH}/ca.pem"


function log {
        msg=$1
        echo "$(date -u) - $msg"
}

# Copies a source file to a destination, ensuring an atomic overwrite of an old
# file (if present). It also ensures the temporary file begins w/ a dot to
# ensure it doesn't get picked up by the plugin autodiscovery mechanism. See:
# https://github.com/kubernetes/community/blob/master/contributors/design-proposals/storage/flexvolume-deployment.md#detailed-design
function safe_copy {
        SRC="$1"
        DST_DIR="$2"

        FNAME="$(basename "${SRC}")"

        cp -a "$SRC" "${DST_DIR}/.${FNAME}"
        mv -f "${DST_DIR}/.${FNAME}" "${DST_DIR}/${FNAME}"
}

function keys_are_valid {
        # node private key exists
        [[ -e "${TLS_NODE_KEY}" ]] || return 1
        # node key is valid
        openssl rsa -in "${TLS_NODE_KEY}" -check -noout >& /dev/null || return 2

        # node PEM exists
        [[ -e "${TLS_NODE_PEM}" ]] || return 3
        # node pem matches key
        KEYMOD="$(openssl rsa -noout -modulus -in "${TLS_NODE_KEY}" | sha512sum)"
        PEMMOD="$(openssl x509 -noout -modulus -in "${TLS_NODE_PEM}" | sha512sum)"
        [[ "Z${KEYMOD}" == "Z${PEMMOD}" ]] || return 4

        # CA PEM exists
        [[ -e "${TLS_CA}" ]] || return 5
        # CA PEM is valid
        openssl x509 -in "${TLS_CA}" -noout || return 6

        # node pem is properly signed
        openssl verify -CAfile "${TLS_CA}" "${TLS_NODE_PEM}"  >& /dev/null || return 7
}

function make_keys {
        # generate host private key
        openssl genrsa -out "${TLS_NODE_KEY}" 4096
        # generate CSR
        openssl req -new -sha256 -key "${TLS_NODE_KEY}" \
            -subj "/CN=${NODE_NAME-unknown}" -days 3650 -out "${TLS_NODE_CSR}"
        # sign CSR
        openssl x509 -req -in ${TLS_NODE_CSR} -CAkey ${CA_KEY} -CA ${CA_PEM} \
            -set_serial "$(date +%s)" -out ${TLS_NODE_PEM} -days 3650
        # install CA PEM
        cp "${CA_PEM}" "${TLS_CA}"
        touch "${VAR_LIB_GLUSTERD}/secure-access"
}

#-- Install the flex plugin
PLUGINDIR="${FLEXVOL_PLUGIN_PATH}/rht~glfs-subvol"
log "Installing plugin"
mkdir -p "${PLUGINDIR}"
mkdir -p "${PLUGINDIR}/.bin"
safe_copy /jq "${PLUGINDIR}/.bin/"
safe_copy /glfs-subvol "${PLUGINDIR}/"

while true; do
        #-- Install TLS keys and keep then up-to-date in case the secret changes
        if [[ -e "${CA_KEY}" && -e "${CA_PEM}" ]]; then
                # Create the node key if it isn't valid
                if ! keys_are_valid; then
                        log "TLS keys are invalid (err: $?). Regenerating."
                        make_keys
                else
                        log "TLS keys are valid"
                fi
        else
                log "CA keys not found, TLS is disabled"
                # CA keys don't exist, turn off SSL on the node
                rm -f "${VAR_LIB_GLUSTERD}/secure-access"
                rm -f "${TLS_NODE_KEY}" "${TLS_NODE_CSR}" "${TLS_NODE_PEM}"
                rm -f "${TLS_CA}"
        fi
        sleep 60
done
