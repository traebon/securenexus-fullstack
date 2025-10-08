#!/bin/bash
# Setup certbot auto-renewal hook
# Run with: sudo bash setup-certbot-renewal.sh

set -e

echo "Creating certbot renewal hook..."

# Create the renewal hook directory if it doesn't exist
mkdir -p /etc/letsencrypt/renewal-hooks/deploy

# Create the import script
cat > /etc/letsencrypt/renewal-hooks/deploy/import-to-traefik.sh << 'HOOK_EOF'
#!/bin/bash
# Auto-import renewed certificates to Traefik
# This runs automatically after certbot renews certificates

set -e

WORK_DIR="/home/tristian/securenexus-fullstack"
CERT_PATH="/etc/letsencrypt/live/securenexus.net"

cd "$WORK_DIR"

echo "Importing renewed certificates to Traefik..."

# Encode certificates
CERT_B64=$(base64 -w0 < "$CERT_PATH/fullchain.pem")
KEY_B64=$(base64 -w0 < "$CERT_PATH/privkey.pem")

# Backup existing acme.json
cp acme/acme.json "acme/acme.json.backup-$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true

# Create new acme.json
cat > acme/acme.json << EOF
{
  "le": {
    "Account": {
      "Email": "admin@securenexus.net",
      "Registration": {
        "body": {
          "status": "valid"
        },
        "uri": ""
      },
      "PrivateKey": "",
      "KeyType": "4096"
    },
    "Certificates": [
      {
        "domain": {
          "main": "securenexus.net",
          "sans": ["*.securenexus.net"]
        },
        "certificate": "$CERT_B64",
        "key": "$KEY_B64",
        "Store": "default"
      }
    ]
  }
}
EOF

# Set permissions
chmod 600 acme/acme.json
chown tristian:tristian acme/acme.json

# Restart Traefik
docker compose restart traefik

echo "✅ Certificates renewed and imported to Traefik"
HOOK_EOF

# Make it executable
chmod +x /etc/letsencrypt/renewal-hooks/deploy/import-to-traefik.sh

echo "✅ Renewal hook created at /etc/letsencrypt/renewal-hooks/deploy/import-to-traefik.sh"
echo ""
echo "Testing renewal (dry run)..."
certbot renew --dry-run

echo ""
echo "✅ Auto-renewal is configured!"
echo ""
echo "Certbot will automatically:"
echo "  1. Renew certificates when they're close to expiration"
echo "  2. Run the import hook to update Traefik"
echo "  3. Restart Traefik with new certificates"
echo ""
echo "You can manually test renewal anytime with:"
echo "  sudo certbot renew --dry-run"
