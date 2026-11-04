#!/bin/sh
set -euo pipefail

validate_inputs() {
    for var in IMAGE IMAGE_SHA GITHUB_SHA GITHUB_REPOSITORY GITHUB_REF_NAME UPWIND_API_ENDPOINT UPWIND_AUTH_ENDPOINT UPWIND_CLIENT_ID UPWIND_CLIENT_SECRET UPWIND_ORGANIZATION_ID; do
        if [ -z "$(printenv "$var" || true)" ]; then
            echo "Error: $var is required and cannot be empty."
            exit 1
        fi
    done

    # pull_request_id may be a single number or a comma-separated list of numbers.
    PULL_REQUEST_ID=$(printf '%s' "${PULL_REQUEST_ID:-}" | tr -d '[:space:]')
    if [ -n "$PULL_REQUEST_ID" ] && ! printf '%s' "$PULL_REQUEST_ID" | grep -Eq '^[0-9]+(,[0-9]+)*$'; then
        echo "Error: pull_request_id must be a number or a comma-separated list of numbers."
        exit 1
    fi
}

get_access_token() {
    response=$(curl -sS --location "${UPWIND_AUTH_ENDPOINT}/oauth/token" \
        --header "Content-Type: application/x-www-form-urlencoded" \
        --data-urlencode "grant_type=client_credentials" \
        --data-urlencode "audience=${UPWIND_API_ENDPOINT}" \
        --data-urlencode "client_id=${UPWIND_CLIENT_ID}" \
        --data-urlencode "client_secret=${UPWIND_CLIENT_SECRET}") || true

    # `// empty` so a missing/null token yields "" instead of the string "null".
    ACCESS_TOKEN=$(printf '%s' "$response" | jq -r '.access_token // empty' 2>/dev/null || true)
    if [ -z "$ACCESS_TOKEN" ]; then
        echo "Error: Unable to obtain access token."
        exit 1
    fi
    # Make sure the token never shows up in the build log.
    echo "::add-mask::${ACCESS_TOKEN}"
    echo "Successfully obtained access token."
}

build_payload() {
    # jq handles all escaping; no user input is ever interpreted by the shell.
    jq -n \
        --arg image "$IMAGE" \
        --arg commit_sha "$GITHUB_SHA" \
        --arg repository "https://github.com/${GITHUB_REPOSITORY}.git" \
        --arg branch "$GITHUB_REF_NAME" \
        --arg image_sha "$IMAGE_SHA" \
        --arg build_time "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
        --arg prs "$PULL_REQUEST_ID" \
        --arg user "${USERNAME:-}" \
        '{
            type: "image_build",
            reporter: "github_actions",
            data: ({
                image: $image,
                commit_sha: $commit_sha,
                repository: $repository,
                branch: $branch,
                image_sha: $image_sha,
                build_time: $build_time
            }
            + (if $prs  != "" then {pull_request_ids: ($prs | split(",") | map(tonumber))} else {} end)
            + (if $user != "" then {user: $user} else {} end))
        }'
}

create_event() {
    JSON_PAYLOAD=$(build_payload)
    EVENTS_URL="${UPWIND_API_ENDPOINT}/v1/organizations/${UPWIND_ORGANIZATION_ID}/events"

    if [ "${DRY_RUN:-false}" = "true" ]; then
        echo "[DRY_RUN]: Would POST to ${EVENTS_URL} with payload:"
        printf '%s\n' "$JSON_PAYLOAD"
        return 0
    fi

    echo "Creating event..."
    # Arguments are passed directly to curl (no eval); the payload goes via stdin.
    response=$(printf '%s' "$JSON_PAYLOAD" | curl -sS --location "$EVENTS_URL" \
        --request POST \
        --write-out '\n%{http_code}' \
        --header "Content-Type: application/json" \
        --header "Authorization: Bearer ${ACCESS_TOKEN}" \
        --data-binary @-)
    response_code=$(printf '%s\n' "$response" | tail -n 1)
    response_body=$(printf '%s\n' "$response" | sed '$ d')

    echo "Status Code: ${response_code}"
    echo "Response:"
    printf '%s\n' "$response_body" | jq '.' 2>/dev/null || printf '%s\n' "$response_body"

    # Never fail the customer's build because of the event call; just surface a warning.
    case "$response_code" in
        2??) ;;
        *) echo "::warning::Upwind image build event was not created (HTTP ${response_code})." ;;
    esac
}

main() {
    validate_inputs
    get_access_token
    create_event
}

main
