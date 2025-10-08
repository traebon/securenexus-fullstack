#!/bin/bash
# Certbot cleanup hook for DNS-01 challenge
# This script is called by certbot to remove the TXT record

set -e

ZONE_FILE="/home/tristian/securenexus-fullstack/dns/zones/securenexus.net.zone"
WORK_DIR="/home/tristian/securenexus-fullstack"

echo "Cleaning up TXT record for domain: $CERTBOT_DOMAIN"

cd "$WORK_DIR"

# Get current serial
CURRENT_SERIAL=$(grep "serial" "$ZONE_FILE" | awk '{print $1}')
NEW_SERIAL=$((CURRENT_SERIAL + 1))

# Remove the TXT record
sed -i "/_acme-challenge.securenexus.net.*TXT.*$CERTBOT_VALIDATION/d" "$ZONE_FILE"

# Update serial
sed -i "s/$CURRENT_SERIAL ; serial/$NEW_SERIAL ; serial/" "$ZONE_FILE"

# Restart CoreDNS
docker compose restart coredns

echo "✅ TXT record cleaned up"
