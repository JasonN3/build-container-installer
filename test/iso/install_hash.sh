#!/bin/bash

set -ex

checkisomd5 ../../${ISO_NAME}
cd $(dirname ../../${ISO_NAME}) && sha256sum -c $(basename ${ISO_NAME})-CHECKSUM