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
    if [[ -f ${PWD}/${file} ]]
    then
        echo "-map ${PWD}/${file} ${file:2}"
        echo "-chmod 0444 ${file:2}"
    fi
done
popd > /dev/null

if [[ -n "${FLATPAK_DIR}" ]]
then
    pushd "${FLATPAK_DIR}" > /dev/null
    for file in $(find repo)
    do
        if [[ "${file}" == "repo/.lock" ]]
        then
            continue
        fi
        echo "-map ${PWD}/${file} flatpak/${file}"
        echo "-chmod 0444 flatpak/${file}"
    done
    popd > /dev/null
fi

if [ -f "${PWD}/../sb_pubkey.der" ]
then
	echo "-map ${PWD}/../sb_pubkey.der sb_pubkey.der"
	echo "-chmod 0444 /sb_pubkey.der"
fi

pushd "${PWD}/../container/${IMAGE_NAME}-${IMAGE_TAG}" > /dev/null
for file in $(find)
do
    echo "-map ${PWD}/${file} container/${file}"
    echo "-chmod 0444 container/${file}"
done
popd > /dev/null
echo "-end"
