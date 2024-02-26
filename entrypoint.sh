#!/bin/bash

set -ex

make container/${IMAGE_NAME}-${IMAGE_TAG} $@

make boot.iso $@

make build/deploy.iso $@

mv build /github/workspace/