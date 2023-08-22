#!/bin/sh

set -eu

# Configurations from inputs
DRY=${DRY:-false}

validate_inputs() {
    for var in IMAGE_SHA GITHUB_REPOSITORY GITHUB_REF_NAME API_URL UPWIND_CLIENT_ID UPWIND_CLIENT_SECRET UPWIND_ORGANIZATION_ID AUTH_URL; do
        if [ -z "$(eval echo \$$var)" ]; then
            echo "Error: $var is not set or empty"
            exit 1
        fi
    done
}

# Gets the access token
get_access_token() {
    response=$(curl -s --location "${AUTH_URL}/oauth/token" \
    --header "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "grant_type=client_credentials" \
    --data-urlencode "audience=${API_URL}" \
    --data-urlencode "client_id=${UPWIND_CLIENT_ID}" \
    --data-urlencode "client_secret=${UPWIND_CLIENT_SECRET}")

    ACCESS_TOKEN=$(echo "$response" | jq -r '.access_token')

    if [ -z "$ACCESS_TOKEN" ]; then
        echo "Failed to get access token"
        exit 1
    fi
    echo "Got access token successfully"
}

# Sends the CI event to Upwind
send_ci_event() {
    CURL_CMD="curl -s --location \"${API_URL}/v1/organizations/$UPWIND_ORGANIZATION_ID/events\" \
    --request POST \
    --write-out \"\n%{http_code}\" \
    --header \"Content-Type: application/json\" \
    --header \"Authorization: Bearer $ACCESS_TOKEN\" \
    --data '{
       \"type\": \"image_build\",
       \"reporter\": \"github_actions\",
       \"data\" :{
         \"image\" : \"${IMAGE}\",
         \"commit_sha\" : \"${GITHUB_SHA}\",
         \"repository\": \"https://github.com/${GITHUB_REPOSITORY}.git\",
         \"branch\": \"${GITHUB_REF_NAME}\",
         \"image_sha\": \"${IMAGE_SHA}\",
         \"build_time\" : \"$(date +'%Y-%m-%dT%H:%M:%S')\"
       }
     }'
     "

    if [ "${DRY}" == "true" ]; then
        echo "DRY MODE: The curl command is:"
        echo "${CURL_CMD}"
    else
        echo "The curl command is:"
        echo "${CURL_CMD}"
        echo "Sending CI event..."
        response=$(eval "${CURL_CMD}")
        echo "Response: ${response}"
    fi
}


main() {
    validate_inputs
    get_access_token
    send_ci_event
}

main