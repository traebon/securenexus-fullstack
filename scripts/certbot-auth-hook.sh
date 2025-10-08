#!/bin/bash
# Certbot authentication hook for DNS-01 challenge
# This script is called by certbot to add the TXT record

set -e

ZONE_FILE="/home/tristian/securenexus-fullstack/dns/zones/securenexus.net.zone"
WORK_DIR="/home/tristian/securenexus-fullstack"

# CERTBOT_DOMAIN is provided by certbot (e.g., securenexus.net)
# CERTBOT_VALIDATION is the TXT record value

echo "Adding TXT record for domain: $CERTBOT_DOMAIN"
echo "TXT value: $CERTBOT_VALIDATION"

cd "$WORK_DIR"

# Get current serial
CURRENT_SERIAL=$(grep "serial" "$ZONE_FILE" | awk '{print $1}')
NEW_SERIAL=$((CURRENT_SERIAL + 1))

# Check if TXT record already exists
if grep -q "_acme-challenge.securenexus.net.*TXT.*$CERTBOT_VALIDATION" "$ZONE_FILE"; then
    echo "TXT record already exists, skipping..."
else
    # Add TXT record after wildcard line
    sed -i "/^\*.securenexus.net/a _acme-challenge.securenexus.net. 120 IN TXT \"$CERTBOT_VALIDATION\"" "$ZONE_FILE"
    echo "TXT record added to zone file"
fi

# Update serial
sed -i "s/$CURRENT_SERIAL ; serial/$NEW_SERIAL ; serial/" "$ZONE_FILE"

# Restart CoreDNS
docker compose restart coredns

echo "Waiting 30 seconds for DNS propagation..."
sleep 30

# Verify TXT record is live
dig @localhost _acme-challenge.securenexus.net TXT +short

echo "✅ DNS challenge ready"
