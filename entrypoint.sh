#!/bin/sh
set -euo pipefail

validate_inputs() {
    for var in IMAGE_SHA GITHUB_REPOSITORY GITHUB_REF_NAME UPWIND_API_ENDPOINT UPWIND_AUTH_ENDPOINT UPWIND_CLIENT_ID UPWIND_CLIENT_SECRET UPWIND_ORGANIZATION_ID; do
        if [ -z "$(eval echo \$$var)" ]; then
            echo "Error: $var is required and cannot be empty."
            exit 1
        fi
    done
}

get_access_token() {
    response=$(curl -s --location "${UPWIND_AUTH_ENDPOINT}/oauth/token" \
    --header "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "grant_type=client_credentials" \
    --data-urlencode "audience=${UPWIND_API_ENDPOINT}" \
    --data-urlencode "client_id=${UPWIND_CLIENT_ID}" \
    --data-urlencode "client_secret=${UPWIND_CLIENT_SECRET}")
    ACCESS_TOKEN=$(echo "$response" | jq -r '.access_token')
    if [ -z "$ACCESS_TOKEN" ]; then
        echo "Error: Unable to obtain access token."
        exit 1
    fi
    echo "Successfully obtained access token."
}

create_event() {
    # Add pull_request_ids to the data if PULL_REQUEST_ID is provided
    if [ -n "${PULL_REQUEST_ID:-}" ]; then
        PULL_REQUEST_IDS_JSON="\"pull_request_ids\": [${PULL_REQUEST_ID}]"
    else
        PULL_REQUEST_IDS_JSON=""
    fi

    # Add user to the data if USER_NAME is provided
    if [ -n "${USER_NAME:-}" ]; then
        USER_NAME_JSON="\"user\": \"${USER_NAME}\""
    else
        USER_NAME_JSON=""
    fi

    # Construct the JSON payload
    JSON_PAYLOAD=$(cat <<EOF
{
   "type": "image_build",
   "reporter": "github_actions",
   "data": {
     "image": "${IMAGE}",
     "commit_sha": "${GITHUB_SHA}",
     "repository": "https://github.com/${GITHUB_REPOSITORY}.git",
     "branch": "${GITHUB_REF_NAME}",
     "image_sha": "${IMAGE_SHA}",
     "build_time": "$(date +'%Y-%m-%dT%H:%M:%SZ')"
     $(if [ -n "$PULL_REQUEST_IDS_JSON" ]; then echo ", $PULL_REQUEST_IDS_JSON"; fi)
     $(if [ -n "$USER_NAME_JSON" ]; then echo ", $USER_NAME_JSON"; fi)
   }
}
EOF
)
    echo ${JSON_PAYLOAD}

    CURL_CMD="curl -fsSL \"${UPWIND_API_ENDPOINT}/v1/organizations/$UPWIND_ORGANIZATION_ID/events\" \
    --request POST \
    --write-out \"\n%{http_code}\" \
    --header \"Content-Type: application/json\" \
    --header \"Authorization: Bearer $ACCESS_TOKEN\" \
    --data '${JSON_PAYLOAD}'"

    DRY_RUN=${DRY_RUN:-false}
    if [ "${DRY_RUN}" == "true" ]; then
        echo "[DRY_RUN]: The cURL command is:"
        echo "${CURL_CMD}"
    else
        echo "Creating event..."
        response=$(eval "${CURL_CMD}")
        response_code=$(echo "${response}" | tail -n 1)
        response_body=$(echo "${response}" | sed '$ d' | jq '.')
        echo "Status Code: ${response_code}"
        echo "Response:"
        echo "${response_body}"
    fi
}

main() {
    validate_inputs
    get_access_token
    create_event
}

main
