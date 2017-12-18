FROM centos:7

COPY volrecycler/k8s.repo /etc/yum.repos.d/k8s.repo
RUN yum install -y \
      bash \
      kubectl \
    && yum clean all && \
    rm -rf /var/cache/yum

COPY volrecycler/recycler.sh /
COPY volrecycler/locker.sh /

RUN chmod 755 /recycler.sh && \
    chmod 755 /locker.sh

ENTRYPOINT [ "/locker.sh" ]
