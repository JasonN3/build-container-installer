#!/bin/bash

set -ex

# Create /dev/loop0 if it doesn't already exist. `losetup` has an issue creating it during the first run
mknod -m 0660 /dev/loop0 b 7 0 2>/dev/null || true

if [[ -d /cache/skopeo ]]
then
  ln -s /cache/skopeo /build-container-installer/container
fi

if [[ ! -d /cache/dnf ]]
then
  mkdir /cache/dnf
fi

# Run make command
make "$@"
