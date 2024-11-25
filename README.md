# Create Image Build Event Action

## Description

This GitHub Action creates an image build event in Upwind.

## Inputs

| Name                      | Description                                                                                             | Default                  | Required |
|---------------------------|---------------------------------------------------------------------------------------------------------| ------------------------ |----------|
| `dry`                     | The execution mode of the action. Setting it to `'true'` simulates event creation without executing it. | `'false'`                | `false`  |
| `image`                   | The image associated with the build event.                                                              |                          | `true`   |
| `image_sha`               | The image SHA associated with the build event.                                                          |                          | `true`   |
| `username`                | The user name associated with the build even.                                                           |                          | `false`  |
| `pull_request_id`         | The pull request associated with the build even.                                                        |                          | `false`  |
| `upwind_api_endpoint`     | The Management API endpoint.                                                                            | `https://api.upwind.io`  | `false`  |
| `upwind_auth_endpoint`    | The Authentication API endpoint.                                                                        | `https://auth.upwind.io` | `false`  |
| `upwind_client_id`        | The client ID used for authentication with the Upwind Authorization Service.                            |                          | `true`   |
| `upwind_client_secret`    | The client secret for authentication with the Upwind Authorization Service.                             |                          | `true`   |
| `upwind_organization_id`  | The identifier of the Upwind organization associated with the event.                                    |                          | `true`   |

## Usage

```yaml
name: Build
on:
  push:
    branches:
      - main
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Create Image Build Event
        uses: upwindsecurity/create-image-build-event-action@v3
        with:
          image: "<IMAGE_NAME>"
          image_sha: "<IMAGE_SHA>"
          pull_request_id: "<PULL_REQUEST_ID>"
          username: "<USERNAME>"
          upwind_client_id: ${{ secrets.UPWIND_CLIENT_ID }}
          upwind_client_secret: ${{ secrets.UPWIND_CLIENT_SECRET }}
          upwind_organization_id: ${{ secrets.UPWIND_ORGANIZATION_ID }}
```
