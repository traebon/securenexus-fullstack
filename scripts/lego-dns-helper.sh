#!/bin/bash
# Helper script to update DNS TXT records for lego DNS-01 challenge

set -e

ZONE_FILE="dns/zones/securenexus.net.zone"
TXT_VALUE="$1"

if [ -z "$TXT_VALUE" ]; then
    echo "Usage: $0 <TXT_VALUE>"
    echo "Example: $0 'abc123def456'"
    exit 1
fi

# Read current serial
CURRENT_SERIAL=$(grep "serial" "$ZONE_FILE" | awk '{print $1}')
NEW_SERIAL=$((CURRENT_SERIAL + 1))

echo "Updating zone file..."
echo "Current serial: $CURRENT_SERIAL"
echo "New serial: $NEW_SERIAL"
echo "TXT value: $TXT_VALUE"

# Create backup
cp "$ZONE_FILE" "$ZONE_FILE.bak"

# Add or update TXT record
if grep -q "_acme-challenge.securenexus.net" "$ZONE_FILE"; then
    # Record exists, update it
    sed -i "/_acme-challenge.securenexus.net/d" "$ZONE_FILE"
fi

# Add new TXT record before the closing line
sed -i "/^\*.securenexus.net/a _acme-challenge.securenexus.net. 120 IN TXT \"$TXT_VALUE\"" "$ZONE_FILE"

# Update serial
sed -i "s/$CURRENT_SERIAL ; serial/$NEW_SERIAL ; serial/" "$ZONE_FILE"

echo "✅ Zone file updated"
echo ""
echo "Restarting CoreDNS..."
docker compose restart coredns

sleep 3

echo ""
echo "Verifying TXT record..."
dig @localhost _acme-challenge.securenexus.net TXT +short

echo ""
echo "✅ Done! Press Enter in lego to continue."
