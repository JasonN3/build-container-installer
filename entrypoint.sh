#!/bin/bash

set -ex

for entry in $@; do
	export $entry
done

# Pull container
make container/${IMAGE_NAME}-${IMAGE_TAG} $@

# Build base ISO
make boot.iso $@

# Add container to ISO
make build/deploy.iso $@

mv build/deploy.iso build/${IMAGE_NAME}-${VERSION}.iso
