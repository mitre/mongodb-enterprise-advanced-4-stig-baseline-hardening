#!/bin/bash
set -uo pipefail

# catch misnamed Trivy report
if [ -f "reports/aquasecurity - aquasecurity.json" ]; then
    mv "reports/aquasecurity - aquasecurity.json" "reports/Aqua Security - Trivy.json"
fi

saf validate threshold -F inspec.threshold.yml -i "$REPORT_DIR/Aqua Security - Trivy.json"
INSPEC_THRESHOLD_CHECK=$?
saf validate threshold -F trivy.threshold.yml -i "$REPORT_DIR/inspec_results.json"
TRIVY_THRESHOLD_CHECK=$?

if  [ $INSPEC_THRESHOLD_CHECK -eq 0 ] && [ $TRIVY_THRESHOLD_CHECK -eq 0 ]; then
    docker tag $TARGET_IMAGE:testing $TARGET_IMAGE:passed
    docker image rm $TARGET_IMAGE:testing
    exit 0
else
    docker tag $TARGET_IMAGE:testing $TARGET_IMAGE:failed
    docker image rm $TARGET_IMAGE:testing
    exit 1
fi