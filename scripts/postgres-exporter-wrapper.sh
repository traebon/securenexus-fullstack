#!/bin/sh
# Read password from secret and URL-encode it
PASSWORD=$(cat /run/secrets/postgres_password | tr -d '\n')

# URL-encode the password using printf and sed
ENCODED_PASSWORD=$(printf '%s' "$PASSWORD" | sed 's/+/%2B/g; s#/#%2F#g; s/=/%3D/g')

# Set DATA_SOURCE_NAME environment variable with URL-encoded password
export DATA_SOURCE_NAME="postgresql://authentik:${ENCODED_PASSWORD}@authentik_db:5432/authentik?sslmode=disable"

# Execute the exporter
exec /bin/postgres_exporter
