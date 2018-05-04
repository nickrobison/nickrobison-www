#!/bin/sh

export OPAMJOBS=2
export OPAMYES=1
eval `opam config env`
opam depext -ui mirage
cd src
make clean
mirage configure -t unix --net=socket --http-port=8080
rm -f main.native
make
