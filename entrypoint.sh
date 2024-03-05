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

# Make output dir in github workspace
mkdir ${OUTPUT_DIR} || true

# Copy resulting iso to github workspace and fix permissions
cp build/deploy.iso ${OUTPUT_DIR}
chmod -R ugo=rwX ${OUTPUT_DIR}
echo "::set-output name=iso::${OUTPUT_DIR}/deploy.iso"
