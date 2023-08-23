#!/bin/bash
set -uo pipefail

if saf validate threshold -F threshold.yaml -i $outputFile; then
    docker tag $TARGET_IMAGE:testing $TARGET_IMAGE:passed
    docker image rm $TARGET_IMAGE:testing
    exit 0
else
    docker tag $TARGET_IMAGE:testing $TARGET_IMAGE:failed
    docker image rm $TARGET_IMAGE:testing
    exit 1
fi