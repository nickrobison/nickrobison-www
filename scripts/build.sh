#!/bin/bash

set -e

# We currently need the dev version of yaml and our own cowabloga
opam pin add -y cowabloga https://github.com/nickrobison/cowabloga.git
#opam pin add -y yaml https://github.com/avsm/ocaml-yaml#1dc0233449f93ccea2cc6272804551042b5e64b8

pushd src
mirage configure -t ${MIRAGE_IMAGE} --dhcp=true --http-port=80 --host=${HOSTNAME} --build-id=${BUILD_ID}
make depends
make -j2
popd
.
