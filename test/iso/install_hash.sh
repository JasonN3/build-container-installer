#!/bin/bash

set -ex

checkisomd5 ${ISO}
cd $(dirname ${ISO}) && sha256sum -c $(basename ${ISO})-CHECKSUM