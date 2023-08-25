#!/bin/bash
set -uo pipefail

saf view summary -i $REPORT_DIR/*.json
if $REPORT_TO_HEIMDALL
then 
    for f in $REPORT_DIR/*.json
    do
        curl -F "data=@$(pwd)/$f" \
        -F "filename=$f" \
        -F 'public=false' \
        -H "Authorization: Api-Key $API_KEY" \
        "https://localhost/evaluations" \
        -k
    done
else
    exit 0
fi