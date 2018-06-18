#!/bin/bash

# If there's no cache dir, then we need to init things
if [ -d /home/travis/.opam/${OCAML_VERSION_FULL} ]; then
    echo "Switch exists, not initializing"
    export OPAM_INIT=false
fi


OPAM_INIT=${OPAM_INIT:-true}
# the base opam repository to use for bootstrapping and catch-all namespace
BASE_REMOTE=${BASE_REMOTE:-git://github.com/ocaml/opam-repository}

sudo add-apt-repository --yes ppa:avsm/ocaml42+opam12
sudo apt-get update -qq

sudo apt-get install -y opam

OPAM_SWITCH=${OPAM_SWITCH:-$OCAML_FULL_VERSION}

export OPAMYES=1

case $OPAM_INIT in
    true)
        opam init -a "$BASE_REMOTE" --comp="$OPAM_SWITCH"
        eval $(opam config env)
        ;;
esac

ocaml -version
opam --version
opam --git-version
