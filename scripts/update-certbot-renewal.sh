#!/bin/bash
# Update certbot renewal configuration to use auth hooks
# Run with: sudo bash update-certbot-renewal.sh

set -e

RENEWAL_CONF="/etc/letsencrypt/renewal/securenexus.net.conf"
WORK_DIR="/home/tristian/securenexus-fullstack"

echo "Updating certbot renewal configuration..."

# Backup original config
cp "$RENEWAL_CONF" "$RENEWAL_CONF.backup-$(date +%Y%m%d-%H%M%S)"

# Add manual auth hooks to the renewal config
cat >> "$RENEWAL_CONF" << EOF

# Automatic renewal hooks
manual_auth_hook = $WORK_DIR/certbot-auth-hook.sh
manual_cleanup_hook = $WORK_DIR/certbot-cleanup-hook.sh
EOF

echo "✅ Renewal configuration updated"
echo ""
echo "Testing renewal with new hooks..."
certbot renew --dry-run --cert-name securenexus.net

echo ""
echo "✅ Auto-renewal is now configured!"
echo ""
echo "Certbot will automatically:"
echo "  1. Run auth hook to add TXT record"
echo "  2. Wait for DNS propagation"
echo "  3. Complete ACME challenge"
echo "  4. Run cleanup hook to remove TXT record"
echo "  5. Run deploy hook to import to Traefik"
