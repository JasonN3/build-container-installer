#!/bin/bash

set -ex

# Create /dev/loop0 if it doesn't already exist. `losetup` has an issue creating it during the first run
mknod -m 0660 /dev/loop0 b 7 0 2>/dev/null || true

for i
do
  key=$(echo ${i} | cut -d= -f1)
  value=$(echo ${i} | cut -d= -f2-)
  export ${key}="${value}"
done

if [[ -d /cache/skopeo ]]
then
  ln -s /cache/skopeo /build-container-installer/container
fi

if [[ ! -d /cache/dnf ]]
then
  mkdir /cache/dnf
fi

# Pull container
make container/${IMAGE_NAME}-${IMAGE_TAG} "$@"

# Build base ISO
make boot.iso "$@"

# Add container to ISO
make build/deploy.iso "$@"

# Make output dir in github workspace
mkdir /github/workspace/build || true

# Copy resulting iso to github workspace and fix permissions
cp build/deploy.iso /github/workspace/build
chmod -R ugo=rwX /github/workspace/build
