#!/bin/bash

add_line=$(grep flatpak_manager.add_remote mnt/install/usr/lib64/python*/site-packages/pyanaconda/modules/payloads/payload/rpm_ostree/flatpak_installation.py)

add_line_repo=$(echo "${add_line}" | grep ${FLATPAK_REMOTE_NAME})
add_line_url=$(echo "${add_line}" | grep ${_FLATPAK_REPO_URL})

result=0
if [ -z "${add_line_repo}" ]
then
    echo "Repo name not updated on add_remote line"
    echo "${add_line}"
    result=1
else
    echo "Repo name found on add_remote line"
fi

if [ -z "${add_line_url}" ]
then
    echo "Repo url not updated on add_remote line"
    echo "${add_line}"
    result=1
else
    echo "Repo url found on add_remote line"
fi

replace_line=$(grep flatpak_manager.replace_installed_refs_remote mnt/install/usr/lib64/python*/site-packages/pyanaconda/modules/payloads/payload/rpm_ostree/flatpak_installation.py)

replace_line_repo=$(echo "${replace_line}" | grep ${FLATPAK_REMOTE_NAME})

if [ -z "${replace_line_repo}" ]
then
    echo "Repo name not updated on replace_installed_refs line"
    echo "${replace_line}"
    result=1
else
    echo "Repo name found on replace_installed_refs line"
fi

exit ${result}