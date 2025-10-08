#!/bin/bash
# Import certbot certificates to Traefik
# Run with: sudo ./import-certbot.sh

set -e

CERT_PATH="/etc/letsencrypt/live/securenexus.net"
WORK_DIR="/home/tristian/securenexus-fullstack"

echo "Checking certificate files..."
ls -la "$CERT_PATH/"

echo ""
echo "Encoding certificates..."
CERT_B64=$(base64 -w0 < "$CERT_PATH/fullchain.pem")
KEY_B64=$(base64 -w0 < "$CERT_PATH/privkey.pem")

echo "Backing up existing acme.json..."
cd "$WORK_DIR"
cp acme/acme.json acme/acme.json.pre-certbot-$(date +%Y%m%d-%H%M%S) 2>/dev/null || true

echo "Creating new acme.json..."
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

chmod 600 acme/acme.json
chown tristian:tristian acme/acme.json

echo ""
echo "✅ Certificates imported to acme/acme.json"
ls -la acme/acme.json

echo ""
echo "Restarting Traefik..."
cd "$WORK_DIR"
docker compose restart traefik

echo ""
echo "Waiting for Traefik to start..."
sleep 5

echo ""
echo "Testing SSL certificate..."
curl -v https://securenexus.net 2>&1 | grep -E "subject:|issuer:" | head -2

echo ""
echo "✅ Done! Your wildcard certificate is now active."
echo ""
echo "Certificate covers:"
echo "  - securenexus.net"
echo "  - *.securenexus.net"
echo ""
echo "Expires: $(openssl x509 -enddate -noout -in "$CERT_PATH/fullchain.pem" | cut -d= -f2)"
