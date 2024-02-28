#!/bin/bash

set -eu

# pre-create loop devices manually. In containers we can't use losetup for that.
mknod -m 0660 /dev/loop0 b 7 0 2>/dev/null || true

make output/${IMAGE_NAME}-${IMAGE_TAG}.iso \
	ARCH=${ARCH} \
	VERSION=${VERSION} \
	IMAGE_REPO=${IMAGE_REPO} \
	IMAGE_NAME=${IMAGE_NAME} \
	IMAGE_TAG=${IMAGE_TAG} \
	VARIANT=${VARIANT} \
	WEB_UI=${WEB_UI} \
	SECURE_BOOT_KEY_URL=${SECURE_BOOT_KEY_URL} \
	ENROLLMENT_PASSWORD=${ENROLLMENT_PASSWORD}
