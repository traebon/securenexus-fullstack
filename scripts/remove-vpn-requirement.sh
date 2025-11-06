#!/bin/bash
# Remove VPN requirement from admin services
# Makes them accessible via Authentik SSO only (no VPN needed)

set -e

echo "🔓 Removing VPN requirement from admin services..."
echo ""

# Backup current compose.yml
cp compose.yml compose.yml.backup-$(date +%Y%m%d-%H%M%S)
echo "✅ Backed up compose.yml"

# Replace admin-vpn with sso in compose.yml
sed -i 's/admin-vpn@file,secure-headers@file/sso@file,secure-headers@file/g' compose.yml

echo "✅ Updated compose.yml (removed admin-vpn middleware)"
echo ""
echo "Services updated:"
echo "  - Portainer"
echo "  - Grafana"
echo "  - Prometheus"
echo "  - Any other services using admin-vpn middleware"
echo ""
echo "These services now require Authentik SSO only (no VPN)"
echo ""

read -p "Restart affected services now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "🔄 Restarting services..."
    docker compose up -d portainer grafana prometheus 2>/dev/null || echo "⚠️  Some services not running (that's OK)"
    echo ""
    echo "✅ Done! You can now access admin services without VPN"
    echo ""
    echo "Access URLs:"
    echo "  - Portainer: https://portainer.securenexus.net"
    echo "  - Grafana: https://grafana.securenexus.net"
    echo "  - Prometheus: https://prometheus.securenexus.net"
    echo ""
    echo "Login with Authentik SSO"
fi

echo ""
echo "To revert: cp compose.yml.backup-* compose.yml && docker compose up -d"
