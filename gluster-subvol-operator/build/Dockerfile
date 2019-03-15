FROM quay.io/operator-framework/helm-operator:v0.5.0

# USER ${USER_UID} is defined in the base image as 1001
# docker doesn't allow an environment substitution for the uid in COPY
COPY --chown=1001:0 helm-charts/ ${HOME}/helm-charts/
COPY --chown=1001:0 watches.yaml ${HOME}/watches.yaml
RUN find ${HOME} -type d -exec chmod go+rx {} \; && \
    find ${HOME} -type f -exec chmod go+r {} \;


ARG builddate="(unknown)"
ARG version="(unknown)"

LABEL org.label-schema.build-date="${builddate}"
LABEL org.label-schema.description="Operator to deploy gluster-subvol components"
LABEL org.label-schema.license="Apache-2.0"
LABEL org.label-schema.name="gluster-subvol operator"
LABEL org.label-schema.schema-version = "1.0"
LABEL org.label-schema.vcs-ref="${version}"
LABEL org.label-schema.vcs-url="https://github.com/gluster/gluster-subvol"
LABEL org.label-schema.vendor="Gluster.org"
LABEL org.label-schema.version="${version}"
