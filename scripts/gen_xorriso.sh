#!/bin/bash

echo "-indev $(pwd)/results/images/boot.iso"
echo "-outdev $(pwd)results/images/deploy.iso"
echo "-boot_image any replay"
echo "-volid Fedora-S-dvd-x86_64-39"
echo "-joliet on"
echo "-compliance joliet_long_names"
cache_files=$(find /registry_cache)
for file in ${cache_files}
do
    file=$(echo $file | sed 's/^\/registry_cache\/\(.*\)/\1/')
    echo "-map $(pwd)/${file} repo_cache/${file}"
    echo "-chmod 0444 repo_cache/${file}"
done
echo "-end"