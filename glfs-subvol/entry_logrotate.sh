#! /bin/bash

set -e -o pipefail

# Volumes that need to be mapped
LOGDIR=/log
# LOGFILE must be defined
if [[ x"${LOGFILE}" == x ]]; then
        echo "LOGFILE env variable must be defined"
        exit 1
fi

# Create config file for logrotate
cat - > /tmp/logrotate.conf <<EOF
        "${LOGDIR}/${LOGFILE}" {
                # Don't rotate, just truncate the file. This should avoid the
                # need for HUP to glusterfs.
                copytruncate

                # It's ok if the log file doesn't exist
                missingok

                # Don't keep old files
                rotate 0

                # Take action when file exceeds 1 MB
                size 1M
        }
EOF

while true; do
        logrotate -v -s /tmp/logrotate.state /tmp/logrotate.conf
        sleep 600
done
