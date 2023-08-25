#!/bin/bash
set -uo pipefail

saf view summary -i $REPORT_DIR/*.json
if curl -F "data=@$(pwd)/$outputFile" \
    -F "filename=$outputFile" \
    -F 'public=false' \
    -H "Authorization: Api-Key $apiKey" \
    "https://localhost/evaluations" \
    -k 
then
    echo -e "\nFile uploaded successfully."
    exit 0
else 
    echo -e "\nFile was not uploaded, error in api calls."
    exit 1
fi