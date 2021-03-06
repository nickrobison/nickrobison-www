#!/bin/bash

# Setup OPAM
export OCAML_FULL_VERSION=4.07
export OCAML_VERSION=4.07

# Mirage settings
export MIRAGE_IMAGE=virtio
export HOSTNAME=www.nickrobison.com
#export BUILD_ID=$(date +%s)

# Google Cloud settings
export GAE_PYTHONPATH=${HOME}/.cache/google_appengine PATH=$PATH:${HOME}/google-cloud-sdk/bin PYTHONPATH=${PYTHONPATH}:${GAE_PYTHONPATH} CLOUDSDK_CORE_DISABLE_PROMPTS=1
export GCLOUD_PROJECT=blog-203416
export GS_BUCKET=nickrobison-blog-images
export IMAGE_FAMILY=mirage-blog
export PUBLIC_IP=35.199.155.136
export INSTANCE_NAME=blog
export GCE_ZONE=us-west1-c
