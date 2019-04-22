#!/bin/bash

# This script is designed to run in the Docker container, and so it pulls in the ENV settings on its own.

set -e

source scripts/env.sh

# We currently need our own cowabloga
opam pin add -y cowabloga https://github.com/nickrobison/cowabloga.git
# Forked version of xapi-rrd with rcp restrictions removed.
opam pin add -y xapi-rrd https://github.com/nickrobison/xcp-rrd.git


pushd src
mirage configure -t ${MIRAGE_IMAGE} --dhcp=true --host=${HOSTNAME} --build-id=${BUILD_ID} --tls=true
make depends
make -j2
popd

# Create the tarball
#solo5-mkimage disk.raw src/nickrobison_www.${MIRAGE_IMAGE}
#tar -zcvf mirage-${BUILD_ID}.tar.gz disk.raw
