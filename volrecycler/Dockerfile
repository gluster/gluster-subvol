FROM centos:7

COPY k8s.repo /etc/yum.repos.d/k8s.repo
RUN yum install -y \
      bash \
      kubectl \
    && yum clean all

COPY recycler.sh /
RUN chmod 755 /recycler.sh

ENTRYPOINT [ "/recycler.sh" ]
