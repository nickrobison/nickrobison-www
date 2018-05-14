#!/bin/bash

set -e

if [ ! -d ${HOME}/google-cloud-sdk ]; then
    curl https://sdk.cloud.google.com | bash;
fi

gcloud auth activate-service-account --key-file client-secret.json
gcloud config set project ${GCLOUD_PROJECT}
