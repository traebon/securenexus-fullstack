#!/bin/bash
# Initialize CrowdSec with proper API credentials

echo "Initializing CrowdSec..."

# Start CrowdSec in background to initialize
docker compose up -d crowdsec

# Wait for CrowdSec to start
echo "Waiting for CrowdSec to initialize..."
sleep 10

# Generate machine credentials for the bouncer
echo "Generating bouncer API key..."
BOUNCER_KEY=$(docker compose exec -T crowdsec cscli bouncers add traefik-bouncer -o raw 2>/dev/null || echo "")

if [ -z "$BOUNCER_KEY" ]; then
    echo "Bouncer might already exist, listing current bouncers:"
    docker compose exec -T crowdsec cscli bouncers list

    # Try to get existing key or regenerate
    echo "Regenerating bouncer key..."
    docker compose exec -T crowdsec cscli bouncers delete traefik-bouncer 2>/dev/null
    BOUNCER_KEY=$(docker compose exec -T crowdsec cscli bouncers add traefik-bouncer -o raw)
fi

# Save the bouncer key
if [ ! -z "$BOUNCER_KEY" ]; then
    echo "$BOUNCER_KEY" > secrets/crowdsec_bouncer_api_key.txt
    echo "✓ Bouncer API key saved to secrets/crowdsec_bouncer_api_key.txt"
else
    echo "✗ Failed to generate bouncer API key"
    exit 1
fi

# Start the bouncer
echo "Starting CrowdSec bouncer..."
docker compose up -d crowdsec_bouncer

# Check status
echo "Checking CrowdSec status..."
docker compose exec -T crowdsec cscli metrics

echo "✓ CrowdSec initialization complete"