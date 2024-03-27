#!/bin/bash

echo "-report_about WARNING"
echo "-indev ${_BASE_DIR}/results/images/boot.iso"
echo "-outdev ${ISO_NAME}"
echo "-boot_image any replay"
echo "-joliet on"
echo "-compliance joliet_long_names"
pushd ${_BASE_DIR}/results > /dev/null
for file in $(find -type f *)
do
    if [[ "$file" == "images/boot.iso" ]]
    then
        continue
    fi
    echo "-map ${_BASE_DIR}/results/${file} ${file}"
    echo "-chmod 0444 ${file}"
done
popd > /dev/null

if [[ -n "${FLATPAK_DIR}" ]]
then
    pushd ${FLATPAK_DIR} > /dev/null
    for file in $(find -type f *)
    do
        echo "-map $(pwd)/${file} flatpak/${file}"
        echo "-chmod 0444 flatpak/${file}"
    done
    popd > /dev/null
fi

if [ -f $(pwd)/sb_pubkey.der ]
then
	echo "-map $(pwd)/sb_pubkey.der sb_pubkey.der"
	echo "-chmod 0444 /sb_pubkey.der"
fi

pushd container > /dev/null
for file in $(find -type f ${IMAGE_NAME}-${IMAGE_TAG})
do
    echo "-map $(pwd)/${file} ${file}"
    echo "-chmod 0444 ${file}"
done
popd > /dev/null
echo "-end"