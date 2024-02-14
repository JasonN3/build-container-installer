#!/bin/bash

echo "-indev $(pwd)/results/images/boot.iso"
echo "-outdev $(pwd)/results/images/deploy.iso"
echo "-boot_image any replay"
echo "-volid Fedora-S-dvd-x86_64-39"
echo "-joliet on"
echo "-compliance joliet_long_names"
for file in $(find base-main-39)
do
    echo "-map $(pwd)/${file} ${file}"
    echo "-chmod 0444 ${file}"
done
echo "-end"