imageID=$(docker commit $targetImage)
docker tag $imageID $targetImage:testing
trivy image --format template --template "$( cat $(pwd)/asff.tpl)" -o trivy-asff.json $targetImage:testing
saf convert trivy2hdf -i trivy-asff.json -o reports
mv ./reports/*aquasecurity.json ./reports/trivyHDF.json
exit 0