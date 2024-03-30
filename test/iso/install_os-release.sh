#!/bin/bash

FOUND_VERSION=$(cat mnt/install/etc/os-release | grep VERSION_ID | cut -d= -f2)

if [[ ${FOUND_VERSION} != ${VERSION} ]]
then
    echo "Version mismatch"
    echo "Expected: ${VERSION}"
    echo "Found: ${FOUND_VERSION}"
    exit 1
else
    echo "Correct version found"
    exit 0
fi