#!/bin/bash

set -e

# We currently need the dev version of yaml and our own cowabloga
opam pin add -y cowabloga https://github.com/nickrobison/cowabloga.git
#opam pin add -y --dev yaml

pushd src
mirage configure -t ${MIRAGE_IMAGE} --dhcp=true --http-port=80 --host=${HOSTNAME} --build-id=${BUILD_ID}
make depends
make -j2
popd
