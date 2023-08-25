# TODO: push results to a Heimdall server. . . ? just one running on localhost for the demo; see github.com/mitre/heimdall2
saf view summary -i $outputFile
loginResult=$(curl 'https://localhost:443/authn/login' \
    -H "Content-Type: application/json" \
    --data-raw '{"email":"****", "password":"****"}' -k)

accessToken=$(jq -r '.accessToken' <<< $loginResult)

apiKeyResult=$(curl 'https://localhost:443/apikeys' \
    -H "Authorization: Bearer $accessToken" \
    -H 'Content-Type: application/json' \
    --data-raw '{"userEmail":"****","currentPassword":"****"}' \
    --compressed -k)

apiKey=$(jq -r '.apiKey' <<< $apiKeyResult)

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