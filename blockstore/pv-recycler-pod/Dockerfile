FROM centos:7

COPY k8s.repo /etc/yum.repos.d/k8s.repo
RUN yum install -y \
      bash \
      coreutil \
      util-linux \
      xfsprogs \
      sed \
      grep \
      kubectl \
    && yum clean all && \
    rm -rf /var/cache/yum

COPY recycler.sh /
COPY locker.sh /

RUN chmod 755 /recycler.sh && \
    chmod 755 /locker.sh

ENTRYPOINT [ "/locker.sh" ]
