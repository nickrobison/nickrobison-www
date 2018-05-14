#!/bin/bash

pushd src
mirage configure -t ${MIRAGE_IMAGE} --dhcp=true --http-port=80 --host=${HOSTNAME}
make depends
make -j2
popd
