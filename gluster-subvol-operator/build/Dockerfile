FROM quay.io/operator-framework/helm-operator:v0.5.0

COPY helm-charts/ ${HOME}/helm-charts/
COPY watches.yaml ${HOME}/watches.yaml

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
