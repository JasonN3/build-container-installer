#!/bin/bash

set -ex

for entry in $@
do
	export $entry
done

# Pull container
make container/${IMAGE_NAME}-${IMAGE_TAG} $@

# Build base ISO
make boot.iso $@

# Add container to ISO
make build/deploy.iso $@

cp build/deploy.iso /github/workspace/build
chmod -R ugo=rwx /github/workspace/build