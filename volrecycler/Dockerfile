FROM centos:7

COPY volrecycler/k8s.repo /etc/yum.repos.d/k8s.repo
RUN yum update -y && \
    yum install -y \
      bash \
      kubectl \
    && yum clean all && \
    rm -rf /var/cache/yum

COPY volrecycler/recycler.sh /
COPY volrecycler/locker.sh /

RUN chmod 755 /recycler.sh && \
    chmod 755 /locker.sh

ARG builddate="(unknown)"
ARG version="(unknown)"

LABEL build-date="${builddate}"
LABEL io.k8s.description="Pod to clean and free gluster-subvol PVs"
LABEL name="gluster/gluster-subvol-volrecycler"
LABEL Summary="Pod to clean and free gluster-subvol PVs"
LABEL vcs-type="git"
LABEL vcs-url="https://github.com/gluster/gluster-subvol"
LABEL vendor="Gluster.org"
LABEL version="${version}"

ENTRYPOINT [ "/locker.sh" ]
