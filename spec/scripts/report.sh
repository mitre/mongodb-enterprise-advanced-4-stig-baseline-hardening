#!/bin/bash
set -uo pipefail

saf view summary -i $REPORT_DIR/*.json
#curl thing to heimdall
exit 0