# TODO: use SAF CLI to check *all* scan output (where possible) against the threshold.yaml file -- see saf-cli.mitre.org
if saf validate threshold -F threshold.yaml -i $outputFile; then
    docker tag $targetImage:testing $targetImage:passed
    docker image rm $targetImage:testing
    exit 0
else
    docker tag $targetImage:testing $targetImage:failed
    docker image rm $targetImage:testing
    exit 1
fi