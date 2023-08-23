#!/bin/bash
set -uo pipefail

saf view summary -i $OUTPUT_FILE
#curl thing to heimdall
exit 0