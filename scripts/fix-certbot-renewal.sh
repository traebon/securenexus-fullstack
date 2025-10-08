#!/bin/bash
# Fix the broken certbot renewal configuration
# Run with: sudo bash fix-certbot-renewal.sh

set -e

RENEWAL_CONF="/etc/letsencrypt/renewal/securenexus.net.conf"

echo "Restoring certbot renewal configuration from backup..."

# Find the most recent backup
BACKUP=$(ls -t ${RENEWAL_CONF}.backup-* 2>/dev/null | head -1)

if [ -n "$BACKUP" ]; then
    echo "Using backup: $BACKUP"
    cp "$BACKUP" "$RENEWAL_CONF"
else
    echo "No backup found, recreating from scratch..."
    cat > "$RENEWAL_CONF" << 'EOF'
# renew_before_expiry = 30 days
version = 2.11.0
archive_dir = /etc/letsencrypt/archive/securenexus.net
cert = /etc/letsencrypt/live/securenexus.net/cert.pem
privkey = /etc/letsencrypt/live/securenexus.net/privkey.pem
chain = /etc/letsencrypt/live/securenexus.net/chain.pem
fullchain = /etc/letsencrypt/live/securenexus.net/fullchain.pem

# Options used in the renewal process
[renewalparams]
account = ****
authenticator = manual
manual_public_ip_logging_ok = True
server = https://acme-v02.api.letsencrypt.org/directory
key_type = ecdsa
EOF
fi

echo ""
echo "Adding manual hooks to renewal config..."

# Add hooks in the proper section
cat >> "$RENEWAL_CONF" << EOF
manual_auth_hook = /home/tristian/securenexus-fullstack/certbot-auth-hook.sh
manual_cleanup_hook = /home/tristian/securenexus-fullstack/certbot-cleanup-hook.sh
EOF

echo ""
echo "✅ Renewal configuration fixed"
echo ""
echo "Testing renewal..."
certbot renew --dry-run --cert-name securenexus.net
