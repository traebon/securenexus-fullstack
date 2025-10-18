#!/bin/bash
set -e

# Read Redis passwords from secrets
REDIS_CACHE_PASS=$(cat /run/secrets/erpnext_redis_cache_password)
REDIS_QUEUE_PASS=$(cat /run/secrets/erpnext_redis_queue_password)

# Update site config with Redis URLs using Python
cd /home/frappe/frappe-bench
python3 << EOF
import json
import urllib.parse

# URL-encode the passwords
cache_pass = urllib.parse.quote("${REDIS_CACHE_PASS}", safe='')
queue_pass = urllib.parse.quote("${REDIS_QUEUE_PASS}", safe='')

# Read current site config
with open('sites/erp.byrne-accounts.org/site_config.json', 'r') as f:
    config = json.load(f)

# Update Redis URLs
config['redis_cache'] = f"redis://:{cache_pass}@erpnext-redis-cache:6379"
config['redis_queue'] = f"redis://:{queue_pass}@erpnext-redis-queue:6379"
config['redis_socketio'] = f"redis://:{cache_pass}@erpnext-redis-cache:6379"

# Write back
with open('sites/erp.byrne-accounts.org/site_config.json', 'w') as f:
    json.dump(config, f, indent=1)
EOF

# Start the scheduler
exec bench --site erp.byrne-accounts.org schedule
