# Container image names
OPERATOR_IMAGE := gluster/gluster-subvol-operator
RECYCLER_IMAGE := gluster/gluster-subvol-volrecycler

OPERATOR_SDK_VERSION := v0.5.0

.PHONY: all
all: subvol-operator volrecycler

BUILDDATE := $(shell date -u '+%Y-%m-%dT%H:%M:%S.%NZ')
VERSION := $(shell git describe --match 'v[0-9]*' --tags --dirty 2> /dev/null || git describe --always --dirty)

.PHONY: install-operator-sdk
OPERATOR_SDK_URL := https://github.com/operator-framework/operator-sdk/releases/download/$(OPERATOR_SDK_VERSION)/operator-sdk-$(OPERATOR_SDK_VERSION)-x86_64-linux-gnu
install-operator-sdk:
	curl -L "${OPERATOR_SDK_URL}" > /tmp/operator-sdk
	sudo install -m 0755 -o root -g root /tmp/operator-sdk /usr/local/bin/operator-sdk

.PHONY: subvol-operator
subvol-operator:
	cd gluster-subvol-operator && \
	operator-sdk build $(OPERATOR_IMAGE) \
	  --docker-build-args "--build-arg builddate=$(BUILDDATE) --build-arg version=$(VERSION)"

.PHONY: volrecycler
volrecycler:
	docker build -t $(RECYCLER_IMAGE) \
	  --build-arg builddate=$(BUILDDATE) \
	  --build-arg version=$(VERSION) \
	  -f volrecycler/Dockerfile \
	  .
