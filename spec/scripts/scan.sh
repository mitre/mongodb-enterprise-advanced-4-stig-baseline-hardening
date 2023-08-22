trivy image --format template --template "$( cat $(pwd)/asff.tpl)" -o trivy-asff.json $targetImage
saf convert trivy2hdf -i trivy-asff.json -o output-folder
if test -f "scanHDF.json"; then
    rm scanHDF.json
fi
mv ./output-folder/*.json scanHDF.json
exit 0