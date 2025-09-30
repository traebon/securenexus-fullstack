#!/bin/bash
# VPN Connection Test Script

echo "=== SecureNexus VPN Connection Test ==="
echo ""

# Check if connected to any VPN
if command -v tailscale >/dev/null 2>&1; then
    echo "📡 Tailscale Status:"
    tailscale status 2>/dev/null || echo "  Not connected or not running"
    echo ""
fi

# Check for VPN interface
echo "🔍 Checking VPN interface:"
if ip addr show tailscale0 >/dev/null 2>&1; then
    VPN_IP=$(ip addr show tailscale0 | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)
    echo "  ✅ VPN interface found: $VPN_IP"
else
    echo "  ❌ No VPN interface found"
fi

echo ""

# Test connectivity to Headscale server IP range
echo "🏓 Testing connectivity:"
if ping -c 1 -W 2 100.64.0.1 >/dev/null 2>&1; then
    echo "  ✅ Headscale server reachable"
else
    echo "  ❌ Headscale server not reachable"
fi

echo ""

# Check admin services access
echo "🔒 Testing admin services access:"

SERVICES=("grafana.securenexus.net" "prometheus.securenexus.net" "traefik.securenexus.net")

for service in "${SERVICES[@]}"; do
    if curl -k -s -o /dev/null -w "%{http_code}" "https://$service" | grep -q "200\|401\|403"; then
        echo "  ✅ $service accessible"
    else
        echo "  ❌ $service not accessible"
    fi
done

echo ""
echo "=== Connection Summary ==="
echo "If all tests pass, you can access:"
echo "  - Grafana: https://grafana.securenexus.net"
echo "  - Prometheus: https://prometheus.securenexus.net"
echo "  - Traefik Dashboard: https://traefik.securenexus.net"
echo ""
echo "Note: You may see certificate warnings - this is expected"
echo "until DNS is properly configured."