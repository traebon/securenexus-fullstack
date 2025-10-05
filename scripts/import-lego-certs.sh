#!/bin/bash
# Import lego certificates into Traefik

set -e

LEGO_CERT_DIR=".lego/certificates"
TRAEFIK_CERT_DIR="./acme"

echo "Checking for lego certificates..."

if [ ! -f "$LEGO_CERT_DIR/securenexus.net.crt" ]; then
    echo "Error: Certificate not found at $LEGO_CERT_DIR/securenexus.net.crt"
    echo "Please ensure lego has completed successfully"
    exit 1
fi

echo "Found certificates:"
ls -lh "$LEGO_CERT_DIR/"

# Backup existing acme.json
if [ -f "$TRAEFIK_CERT_DIR/acme.json" ]; then
    echo "Backing up existing acme.json..."
    cp "$TRAEFIK_CERT_DIR/acme.json" "$TRAEFIK_CERT_DIR/acme.json.pre-lego-$(date +%Y%m%d-%H%M%S)"
fi

# Read certificate and key
CERT_B64=$(base64 -w0 < "$LEGO_CERT_DIR/securenexus.net.crt")
KEY_B64=$(base64 -w0 < "$LEGO_CERT_DIR/securenexus.net.key")

# Create acme.json with lego certificates
cat > "$TRAEFIK_CERT_DIR/acme.json" << EOF
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

# Set proper permissions
chmod 600 "$TRAEFIK_CERT_DIR/acme.json"

echo "✅ Certificates imported into $TRAEFIK_CERT_DIR/acme.json"
echo ""
echo "Next step: Restart Traefik to load the new certificates"
echo "  docker compose restart traefik"
