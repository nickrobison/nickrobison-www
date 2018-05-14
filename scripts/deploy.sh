#!/bin/bash

set -e

solo5-mkimage disk.raw nickrobison_www.virtio
tar -zcvf mirage-${BUILD_ID}.tar.gz disk.raw

# Upload the image
gsutil cp mirage-${BUILD_ID}.tar.gz gs://${GS_BUCKET}

# Create a new image from the uploaded archive
gcloud compute images create mirage-${BUILD_ID} --source-uri gs://${GS_BUCKET}/mirage-${BUILD_ID} --family ${IMAGE_FAMILY}
gcloud compute instances delete ${INSTANCE_NAME}
gcloud compute instances create ${INSTANCE_NAME} --image-family ${IMAGE_FAMILY} --machine-type f1-micro --address ${PUBLIC_IP} --tags http-server,https-server
