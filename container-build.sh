#!/bin/sh

export OPAMJOBS=2
export OPAMYES=1
eval `opam config env`
opam depext -ui mirage mirage-solo5
cd src
mirage configure -t virtio --dhcp=true --host=$HOSTNAME
make depends
make
solo-mkimage disk.raw nickrobison_www-virtio
tar -zcvf mirage-${BUILD_ID}.tar.gz disk.raw
