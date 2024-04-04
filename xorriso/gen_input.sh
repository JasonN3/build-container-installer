#!/bin/bash

echo "-report_about WARNING"
echo "-indev ${PWD}/../results/images/boot.iso"
echo "-outdev ${ISO_NAME}"
echo "-boot_image any replay"
echo "-joliet on"
echo "-compliance joliet_long_names"
pushd "${PWD}/../results" > /dev/null
#for file in $(find .)
for file in ./boot/grub2/grub.cfg ./EFI/BOOT/grub.cfg
do
    if [[ "$file" == "./images/boot.iso" ]]
    then
        continue
    fi
    echo "-map ${PWD}/${file} ${file:2}"
    echo "-chmod 0444 ${file:2}"
done
popd > /dev/null

if [[ -n "${FLATPAK_DIR}" ]]
then
    pushd "${FLATPAK_DIR}" > /dev/null
    chmod -R ugo=rX .
    for file in $(find repo)
    do
        if [[ "${file}" == "repo/.lock" ]]
        then
            continue
        fi
        echo "-map ${PWD}/${file} flatpak/${file}"
    done
    popd > /dev/null
fi

if [ -f $(pwd)/sb_pubkey.der ]
then
	echo "-map $(pwd)/../sb_pubkey.der sb_pubkey.der"
	echo "-chmod 0444 /sb_pubkey.der"
fi

pushd "${PWD}/../container" > /dev/null
for file in $(find "${IMAGE_NAME}-${IMAGE_TAG}" -type f)
do
    echo "-map ${PWD}/${file} ${file}"
    echo "-chmod 0444 ${file}"
done
popd > /dev/null
echo "-end"
