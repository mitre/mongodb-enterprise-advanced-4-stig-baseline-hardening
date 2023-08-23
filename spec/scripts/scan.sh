#!/bin/bash

### Run InSpec wrapper profile against hardened target ###
# Note - Packer has an InSpec provisioner plugin, but it doesn't work well with Docker containers
inspec exec $PROFILE \
    -t docker://$CONTAINER_ID \
    --input-file=$INPUT_FILE \
    --reporter cli json:$REPORT_DIR/$REPORT_FILE

### Run Trivy against target ###
trivy image --format template --template "$( cat $(pwd)/asff.tpl)" -o trivy-asff.json $targetImage
saf convert trivy2hdf -i trivy-asff.json -o output-folder
if test -f "scanHDF.json"; then
    rm scanHDF.json
fi
mv ./output-folder/*.json scanHDF.json
exit 0


