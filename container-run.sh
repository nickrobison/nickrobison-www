#!/bin/sh

export OPAMJOBS=2
export OPAMYES=1
eval `opam config env`
opam depext -ui mirage mirage-solo5
cd src
#make clean
mirage configure -t unix --net=socket --http-port=8080
#rm -f main.native
make depends
make
