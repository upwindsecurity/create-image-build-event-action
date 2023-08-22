# Upwind Notify CI Action

## Description
This GitHub Action notifies a CI event to Upwind using the provided image information and authentication credentials.

## Author
Upwind Security

## Inputs

| Name                      | Description                                         | Default                  | Required |
|---------------------------|-----------------------------------------------------|--------------------------|----------|
| `dry`                     | If true, the command will be printed but not sent.  | `'false'`                | `false`  |
| `image`                   | The image associated with the CI event.             |                          | `true`   |
| `image_sha`               | The image SHA associated with the CI event.         |                          | `true`   |
| `api_url`                 | Upwind auth URL.                                    | `'https://api.upwind.io'`| `false`  |
| `upwind_client_id`        | Client ID for upwind authentication.                |                          | `true`   |
| `upwind_client_secret`    | Client secret for upwind authentication.            |                          | `true`   |
| `upwind_organization_id`  | Organization ID for which the CI event is intended. |                          | `true`   |

## Usage

### Example Workflow Configuration

```yaml
name: Upwind Notify CI
on:
  push:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Notify Upwind
        uses: your-username/upwind-notify-ci-action@v1
        with:
          image: '<IMAGE_NAME>'
          image_sha: '<IMAGE_SHA>'
          upwind_client_id: '<CLIENT_ID>'
          upwind_client_secret: '<CLIENT_SECRET>'
          upwind_organization_id: '<ORGANIZATION_ID>'
```

---