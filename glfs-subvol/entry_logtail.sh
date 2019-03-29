#! /bin/bash

set -e -o pipefail

# Volumes that need to be mapped
LOGDIR=/log
# LOGFILE must be defined
if [[ x"${LOGFILE}" == x ]]; then
        echo "LOGFILE env variable must be defined"
        exit 1
fi

cat - > /tmp/rsyslog.conf <<CONF
module(load="imfile"
       Mode="inotify"
       PollingInterval="10")
input(type="imfile"
      File="${LOGDIR}/*.log"
      addMetadata="on"
      freshStartTail="on"
      reopenOnTruncate="on"
      tag="logs")

# This uses the legacy config format because the version in CentOS:7 doesn't
# have the updated omstdout module that accepts the new config format.
\$template outformat,"%TIMESTAMP:::date-rfc3339% %\$!metadata!filename%%msg:::sp-if-no-1st-sp%%msg:::drop-last-lf%\n"
\$ModLoad omstdout
*.* :omstdout:;outformat

#template(name="outformat" type="string"
#         string="%TIMESTAMP:::date-rfc3339% %\$!metadata!filename%%msg:::sp-if-no-1st-sp%%msg:::drop-last-lf%\n"
#         )

#module(load="omstdout")
#action(type="omstdout"
#       template="RSYSLOG_DebugFormat")
CONF

rsyslogd -n -f /tmp/rsyslog.conf
