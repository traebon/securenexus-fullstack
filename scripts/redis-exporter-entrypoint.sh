#!/bin/sh
# Read Redis password from Docker secret
export REDIS_PASSWORD=$(cat /run/secrets/redis_password)

# Start redis_exporter with password
exec /redis_exporter --redis.addr=redis_cache:6379 --redis.password="$REDIS_PASSWORD"
