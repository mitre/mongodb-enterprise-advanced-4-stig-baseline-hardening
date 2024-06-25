#!/bin/bash
set -uo pipefail

### Run InSpec wrapper profile against hardened target ###
# Note - Packer has an InSpec provisioner plugin, but it doesn't work well with Docker containers
echo "--- Running InSpec Profile ($PROFILE) against target ---"

inspec exec $PROFILE \
    -t docker://$CONTAINER_ID \
    --input-file=$INPUT_FILE \
    --reporter cli json:$REPORT_DIR/$REPORT_FILE \
    --no-create-lockfile