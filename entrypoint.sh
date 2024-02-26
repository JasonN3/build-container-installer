#!/bin/bash

set -ex

for entry in $@
do
  export $entry
done

make container/${IMAGE_NAME}-${IMAGE_TAG} $@

make boot.iso $@

make build/deploy.iso $@

mkdir /github/workspace/build || true

cp build/*.iso /github/workspace/build