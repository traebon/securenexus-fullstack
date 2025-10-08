#!/bin/bash
# Setup Grafana OAuth with Authentik
# Run this script and provide your OAuth Client Secret

set -e

echo "=========================================="
echo "Grafana OAuth/OIDC Setup with Authentik"
echo "=========================================="
echo ""
echo "Enter the OAuth Client Secret from Authentik:"
read -s OAUTH_SECRET
echo ""

# Save the client secret
echo "$OAUTH_SECRET" > secrets/grafana_oauth_secret
chmod 644 secrets/grafana_oauth_secret

echo "✅ OAuth secret saved to secrets/grafana_oauth_secret"
echo ""
echo "Restarting Grafana to apply OAuth configuration..."

docker compose restart grafana

echo ""
echo "Waiting for Grafana to start..."
sleep 10

echo ""
echo "=========================================="
echo "✅ Grafana OAuth Setup Complete!"
echo "=========================================="
echo ""
echo "Access Grafana at: https://grafana.securenexus.net"
echo ""
echo "You should now see 'Sign in with Authentik' button"
echo ""
echo "Note: You may need to configure role mapping in Authentik"
echo "      to grant admin access to specific users/groups."
echo ""
