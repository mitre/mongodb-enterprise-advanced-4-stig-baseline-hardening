#!/bin/bash
set -uo pipefail

### Validate the compliance and status counts of the HDF file ###
echo "--- Validating the compliance and status counts of the HDF file ---"

saf validate threshold -F inspec.threshold.yml -i $REPORT_DIR/$ATTESTED_FILE
INSPEC_THRESHOLD_CHECK=$?

if  [ $INSPEC_THRESHOLD_CHECK -eq 0 ]; then
    docker tag $TARGET_IMAGE:latest $TARGET_IMAGE:passed
    echo "$TARGET_IMAGE:passed created"
    exit 0
else
    docker tag $TARGET_IMAGE:latest $TARGET_IMAGE:failed
    echo "$TARGET_IMAGE:failed created"
    exit 1
fi