#!/bin/bash
set -uo pipefail

### Apply attestions to inspec results ###
# Note - Packer has an InSpec provisioner plugin, but it doesn't work well with Docker containers
echo "--- Applying attestations to InSpec results ---"

saf attest apply -i $REPORT_DIR/$ATTESTATION_FILE $REPORT_DIR/$INSPEC_FILE -o $REPORT_DIR/$ATTESTED_FILE 