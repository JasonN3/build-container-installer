#!/bin/bash

echo "-indev $(pwd)/results/images/boot.iso"
echo "-outdev $(pwd)/results/images/deploy.iso"
echo "-boot_image any replay"
echo "-volid Fedora-S-dvd-x86_64-39"
echo "-joliet on"
echo "-compliance joliet_long_names"
echo "-map $(pwd)/container container"
echo "-chmod_r 0444 container"
echo "-end"
