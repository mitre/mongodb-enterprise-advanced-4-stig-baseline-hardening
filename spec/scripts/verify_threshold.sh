#!/bin/bash
set -uo pipefail

saf validate threshold -F inspec.threshold.yml -i "$REPORT_DIR/inspec_results.json"
INSPEC_THRESHOLD_CHECK=$?

if  [ $INSPEC_THRESHOLD_CHECK -eq 0 ]; then
    docker tag $TARGET_IMAGE:testing $TARGET_IMAGE:passed
    docker image rm $TARGET_IMAGE:testing
    exit 0
else
    docker tag $TARGET_IMAGE:testing $TARGET_IMAGE:failed
    docker image rm $TARGET_IMAGE:testing
    exit 1
fi