#!/bin/sh

set -oue pipefail

readonly SECUREBOOT_KEY="/run/install/repo/ublue-os-akmods-public-key.der"
readonly ENROLLMENT_PASSWORD="ublue-os"

if [[ ! -d "/sys/firmware/efi" ]]; then
	echo "EFI mode not detected. Skipping key enrollment."
	exit 0
fi

if [[ ! -f "${SECUREBOOT_KEY}" ]]; then
	echo "Secure boot key not found: ${SECUREBOOT_KEY}"
	exit 1
fi

mokutil --timeout -1 || :
echo -e "${ENROLLMENT_PASSWORD}\n${ENROLLMENT_PASSWORD}" | mokutil --import "${SECUREBOOT_KEY}" || :
