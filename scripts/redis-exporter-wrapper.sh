#!/bin/sh
# Read password from secret
PASSWORD=$(cat /run/secrets/redis_password | tr -d '\n')

# Execute the exporter with password as command-line argument
exec /redis_exporter --redis.addr=redis_cache:6379 --redis.password="$PASSWORD"
