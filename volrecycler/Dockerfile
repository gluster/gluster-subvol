FROM centos:7

COPY volrecycler/k8s.repo /etc/yum.repos.d/k8s.repo
RUN yum install -y \
      bash \
      kubectl \
    && yum clean all && \
    rm -rf /var/cache/yum

COPY volrecycler/recycler.sh /
RUN chmod 755 /recycler.sh

ENTRYPOINT [ "/recycler.sh" ]
