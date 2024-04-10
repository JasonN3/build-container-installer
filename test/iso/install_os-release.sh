#!/bin/bash

FOUND_VERSION=$(grep VERSION_ID mnt/install/etc/os-release | cut -d= -f2 | tr -d '"')

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