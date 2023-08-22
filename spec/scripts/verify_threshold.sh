# TODO: use SAF CLI to check *all* scan output (where possible) against the threshold.yaml file -- see saf-cli.mitre.org
saf validate threshold -F threshold.yaml -i $outputFile
exit 0