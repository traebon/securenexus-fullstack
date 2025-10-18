#!/bin/bash
set -e

# Read secrets and export as environment variables
export DB_PASSWORD=$(cat /run/secrets/erpnext_db_password)
export ADMIN_PASSWORD=$(cat /run/secrets/erpnext_admin_password)
export REDIS_CACHE_PASSWORD=$(cat /run/secrets/erpnext_redis_cache_password)
export REDIS_QUEUE_PASSWORD=$(cat /run/secrets/erpnext_redis_queue_password)

# Update Redis URLs with actual passwords
export REDIS_CACHE="redis://:${REDIS_CACHE_PASSWORD}@erpnext-redis-cache:6379"
export REDIS_QUEUE="redis://:${REDIS_QUEUE_PASSWORD}@erpnext-redis-queue:6379"
export REDIS_SOCKETIO="redis://:${REDIS_QUEUE_PASSWORD}@erpnext-redis-queue:6379"

# Execute the original entrypoint with all arguments
exec /home/frappe/frappe-bench/env/bin/gunicorn -b 0.0.0.0:8000 --workers 4 --threads 2 --timeout 120 frappe.app:application --preload
