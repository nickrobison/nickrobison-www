set -e

source scripts/env.sh

solo5-mkimage disk.raw src/nickrobison_www.${MIRAGE_IMAGE}
tar -zcvf mirage-${BUILD_ID}.tar.gz. disk.raw