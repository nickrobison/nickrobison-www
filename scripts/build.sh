#!/bin/bash

set -e

pushd src
mirage configure -t ${MIRAGE_IMAGE} --dhcp=true --http-port=80 --host=${HOSTNAME} --build-id=${BUILD_ID}
make depends
make -j2
popd
