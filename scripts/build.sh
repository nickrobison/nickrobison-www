#!/bin/bash

# This script is designed to run in the Docker container, and so it pulls in the ENV settings on its own.

set -e

source scripts/env.sh

# We currently need the dev version of yaml and our own cowabloga
#opam pin add -y yaml https://github.com/avsm/ocaml-yaml#1dc0233449f93ccea2cc6272804551042b5e64b8
#opam pin add -y mirage-os-shim https://github.com/hannesm/mirage-os-shim.git#4.06
opam pin add -y cowabloga https://github.com/nickrobison/cowabloga.git


pushd src
mirage configure -t ${MIRAGE_IMAGE} --dhcp=true --host=${HOSTNAME} --build-id=${BUILD_ID} --tls=true
make depends
make -j2
popd

# Create the tarball
#solo5-mkimage disk.raw src/nickrobison_www.${MIRAGE_IMAGE}
#tar -zcvf mirage-${BUILD_ID}.tar.gz disk.raw
