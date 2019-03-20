# Container image names
OPERATOR_REPO_NAMESPACE := gluster
OPERATOR_IMAGE := $(OPERATOR_REPO_NAMESPACE)/gluster-subvol-operator
PLUGIN_IMAGE := $(OPERATOR_REPO_NAMESPACE)/gluster-subvol-plugin
RECYCLER_IMAGE := $(OPERATOR_REPO_NAMESPACE)/gluster-subvol-volrecycler

OPERATOR_SDK_VERSION := v0.5.0

.PHONY: all
all: subvol-operator subvol-plugin subvol-volrecycler

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

.PHONY: subvol-plugin
subvol-plugin:
	cd glfs-subvol && \
	docker build -t $(PLUGIN_IMAGE) \
	  --build-arg builddate=$(BUILDDATE) \
	  --build-arg version=$(VERSION) \
	  .

.PHONY: subvol-volrecycler
subvol-volrecycler:
	docker build -t $(RECYCLER_IMAGE) \
	  --build-arg builddate=$(BUILDDATE) \
	  --build-arg version=$(VERSION) \
	  -f volrecycler/Dockerfile \
	  .
