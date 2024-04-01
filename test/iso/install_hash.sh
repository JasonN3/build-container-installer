#!/bin/bash

#set -ex

checkisomd5 ../../${ISO_NAME}
if [[ $? != 0 ]]
then
    echo "Found:"
    checkisomd5 --md5sumonly ../../${ISO_NAME}
    echo "Expected:"
    implantisomd5 --force ../../${ISO_NAME}
fi

cd $(dirname ../../${ISO_NAME}) && sha256sum -c $(basename ${ISO_NAME})-CHECKSUM