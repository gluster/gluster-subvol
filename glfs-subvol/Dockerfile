FROM centos:7

RUN yum install -y epel-release && \
    yum update -y && \
    yum install -y \
      jq \
      openssl \
    && \
    yum clean all -y && \
    rm -rf /var/cache/yum

RUN mkdir /flexpath && \
    mkdir /glusterd && \
    mkdir /etcssl && \
    mkdir /tlskeys

COPY entry_flexvol.sh glfs-subvol /

ARG builddate="(unknown)"
ARG version="(unknown)"

LABEL org.label-schema.build-date="${builddate}"
LABEL org.label-schema.description="DaemonSet deploy gluster-subvol flexvol plugin"
LABEL org.label-schema.license="Apache-2.0"
LABEL org.label-schema.name="gluster-subvol flexvol plugin"
LABEL org.label-schema.schema-version = "1.0"
LABEL org.label-schema.vcs-ref="${version}"
LABEL org.label-schema.vcs-url="https://github.com/gluster/gluster-subvol"
LABEL org.label-schema.vendor="Gluster.org"
LABEL org.label-schema.version="${version}"
