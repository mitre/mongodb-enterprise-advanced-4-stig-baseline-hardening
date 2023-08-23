#!/bin/bash
set -uo pipefail

### Run InSpec wrapper profile against hardened target ###
# Note - Packer has an InSpec provisioner plugin, but it doesn't work well with Docker containers
echo "--- Running InSpec Profile ($PROFILE) against target ---"
inspec exec $PROFILE \
    -t docker://$CONTAINER_ID \
    --input-file=$INPUT_FILE \
    --reporter cli json:$REPORT_DIR/$REPORT_FILE

### Run Trivy against target ###
echo "--- Running Trivy CVE Scan against target ---"
IMAGE_ID=$(docker commit $TARGET_IMAGE)
docker tag $IMAGE_ID $TARGET_IMAGE:testing
trivy image --format template --template "$( cat $(pwd)/asff.tpl)" -o trivy-asff.json $TARGET_IMAGE:testing
saf convert trivy2hdf -i trivy-asff.json -o $REPORT_DIR
exit 0



