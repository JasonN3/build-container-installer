#!/bin/bash

set -ex

for entry in $@
do
  export $entry
done

make container/${IMAGE_NAME}-${IMAGE_TAG} $@

make boot.iso $@

make build/deploy.iso $@

mv build /github/workspace/