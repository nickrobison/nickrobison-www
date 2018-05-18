#!/bin/bash

set -e

pushd src
solo5-mkimage disk.raw nickrobison_www.${MIRAGE_IMAGE}
tar -zcvf mirage-${BUILD_ID}.tar.gz disk.raw

# Upload the image
gsutil cp mirage-${BUILD_ID}.tar.gz gs://${GS_BUCKET}

# Create a new image from the uploaded archive
gcloud compute images create mirage-${BUILD_ID} --source-uri gs://${GS_BUCKET}/mirage-${BUILD_ID}.tar.gz --family ${IMAGE_FAMILY}

echo "Shutting down instance: ${INSTANCE_NAME}"
gcloud compute instances delete ${INSTANCE_NAME} --zone=${GCE_ZONE}&
PID=$!
while true; do
    sleep 10
    if jobs -rp | grep ${PID} >/dev/null; then
        echo "."
    else
        echo
        break
    fi
done

echo "Creating instance: ${INSTANCE_NAME}"
gcloud compute instances create ${INSTANCE_NAME} --image-family ${IMAGE_FAMILY} --machine-type f1-micro --zone=${GCE_ZONE} --address ${PUBLIC_IP} --tags http-server,https-server&
PID=$!
while true; do
    sleep 10
    if jobs -rp | grep ${PID} >/dev/null; then
        echo "."
    else
        echo
        break
    fi
done

echo "Finished deploying instance"
popd
