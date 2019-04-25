FROM centos:7

COPY volrecycler/k8s.repo /etc/yum.repos.d/k8s.repo
RUN yum update -y && \
    yum install -y \
      bash \
      kubectl \
    && yum clean all && \
    rm -rf /var/cache/yum

COPY volrecycler/kubectl-sa.sh /
COPY volrecycler/recycler.sh /
COPY volrecycler/locker.sh /

RUN chmod 755 /kubectl-sa.sh \
              /locker.sh \
              /recycler.sh

ARG builddate="(unknown)"
ARG version="(unknown)"

LABEL org.label-schema.build-date="${builddate}"
LABEL org.label-schema.description="Pod to clean and free gluster-subvol PVs"
LABEL org.label-schema.license="Apache-2.0"
LABEL org.label-schema.name="gluster-subvol volume recycler"
LABEL org.label-schema.schema-version = "1.0"
LABEL org.label-schema.vcs-ref="${version}"
LABEL org.label-schema.vcs-url="https://github.com/gluster/gluster-subvol"
LABEL org.label-schema.vendor="Gluster.org"
LABEL org.label-schema.version="${version}"

ENTRYPOINT [ "/locker.sh" ]
