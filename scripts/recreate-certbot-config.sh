#!/bin/bash
# Recreate certbot renewal configuration from scratch
# Run with: sudo bash recreate-certbot-config.sh

set -e

RENEWAL_CONF="/etc/letsencrypt/renewal/securenexus.net.conf"

echo "Creating fresh certbot renewal configuration..."

cat > "$RENEWAL_CONF" << 'EOF'
# renew_before_expiry = 30 days
version = 2.11.0
archive_dir = /etc/letsencrypt/archive/securenexus.net
cert = /etc/letsencrypt/live/securenexus.net/cert.pem
privkey = /etc/letsencrypt/live/securenexus.net/privkey.pem
chain = /etc/letsencrypt/live/securenexus.net/chain.pem
fullchain = /etc/letsencrypt/live/securenexus.net/fullchain.pem

[renewalparams]
account = a1b2c3d4e5f6g7h8
authenticator = manual
pref_challs = dns-01,
manual_public_ip_logging_ok = True
server = https://acme-v02.api.letsencrypt.org/directory
key_type = ecdsa
manual_auth_hook = /home/tristian/securenexus-fullstack/certbot-auth-hook.sh
manual_cleanup_hook = /home/tristian/securenexus-fullstack/certbot-cleanup-hook.sh
EOF

chmod 644 "$RENEWAL_CONF"

echo "✅ Configuration created"
echo ""
echo "Testing renewal..."
certbot renew --dry-run --cert-name securenexus.net
