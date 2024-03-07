#!/bin/bash

set -ex

add_line=$(grep flatpak_manager.add_remote /mnt/install/usr/lib64/python*/site-packages/pyanaconda/modules/payloads/payload/rpm_ostree/flatpak_installation.py)

add_line_repo=$(echo ${add_line} | grep ${FLATPAK_REMOTE_NAME})
add_line_url=$(echo ${add_line} | grep ${_flatpak_repo_url})

result=0
if [ -z "${add_line_repo}" ]
then
    echo "Repo name not updated"
    result=1
fi

if [ -z "${add_line_url}" ]
then
    echo "Repo url not updated"
    result=1
fi

replace_line=$(grep flatpak_manager.replace_installed_refs_remote /mnt/install/usr/lib64/python*/site-packages/pyanaconda/modules/payloads/payload/rpm_ostree/flatpak_installation.py)

replace_line_repo=$(echo ${replace_line} | grep ${FLATPAK_REMOTE_NAME})

if [ -z "${replace_line_repo}" ]
then
    echo "Repo name not updated in second line"
    result=1
fi

exit ${result}