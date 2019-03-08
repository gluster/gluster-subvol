# Container image names
RECYCLER_IMAGE := gluster/gluster-subvol-volrecycler


.PHONY: all
all: volrecycler

BUILDDATE := $(shell date -u '+%Y-%m-%dT%H:%M:%S.%NZ')
VERSION := $(shell git describe --match 'v[0-9]*' --tags --dirty 2> /dev/null || git describe --always --dirty)

.PHONY: volrecycler
volrecycler:
	docker build -t $(RECYCLER_IMAGE) \
	  --build-arg builddate=$(BUILDDATE) \
	  --build-arg version=$(VERSION) \
	  -f volrecycler/Dockerfile \
	  .
