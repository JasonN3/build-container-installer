#!/bin/bash

iso=$1

dnf install -y squashfs-tools

mkdir /mnt/{iso,install}

# Mount ISO
mount -o loop $iso /mnt/iso

# Mount squashfs
mount -t squashfs -o loop /mnt/iso/images/install.img /mnt/install

FOUND_VERSION=$(cat /mnt/install/os-release | grep VERSION_ID | cut -d= -f2)

# Cleanup
umount /mnt/install
umount /mnt/iso

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