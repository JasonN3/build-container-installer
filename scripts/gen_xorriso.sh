#!/bin/bash

echo "-indev $(pwd)/results/images/boot.iso"
echo "-outdev $(pwd)/results/images/deploy.iso"
echo "-boot_image any replay"
echo "-volid Fedora-S-dvd-x86_64-39"
echo "-joliet on"
echo "-compliance joliet_long_names"
echo "-map $(pwd)/base-main.tar base-main.tar"
echo "-chmod 0444 base-main.tar"
echo "-end"
