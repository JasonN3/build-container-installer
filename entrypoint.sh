#!/bin/bash

set -ex

for entry in $@
do
  export $entry
done

# Pull container
make container/${IMAGE_NAME}-${IMAGE_TAG} $@

# Build base ISO
make boot.iso DNF_CACHE=/cache/dnf $@

# Add container to ISO
make build/deploy.iso $@

# Make output dir in github workspace
mkdir /github/workspace/build || true

# Copy resulting iso to github workspace and fix permissions
cp build/deploy.iso /github/workspace/build
chmod -R ugo=rwX /github/workspace/build

