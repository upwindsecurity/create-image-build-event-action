# Use a lightweight base image.
FROM alpine:3

# Install necessary dependencies.
RUN apk update && \
    apk add --no-cache \
    curl \
    jq

# Copy the entrypoint script.
COPY entrypoint.sh /entrypoint.sh

# Make it executable.
RUN chmod +x /entrypoint.sh

# Set the entrypoint.
ENTRYPOINT ["/entrypoint.sh"]
