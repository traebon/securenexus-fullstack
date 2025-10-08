#!/bin/bash
# Interactive certbot certificate generation
# Run this script directly in your terminal

echo "========================================="
echo "SSL Certificate Generation with Certbot"
echo "========================================="
echo ""
echo "This script will guide you through generating a wildcard SSL certificate"
echo "for securenexus.net and *.securenexus.net"
echo ""
echo "Press Enter to continue..."
read

echo ""
echo "Step 1: Running certbot..."
echo ""
sudo certbot certonly --manual \
  --preferred-challenges dns \
  --email admin@securenexus.net \
  --agree-tos \
  -d securenexus.net \
  -d '*.securenexus.net'

# Check if certbot succeeded
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Certificates generated successfully!"
    echo ""
    echo "Step 2: Importing certificates to Traefik..."
    echo ""

    # Import certificates
    CERT_PATH="/etc/letsencrypt/live/securenexus.net"

    if [ ! -f "$CERT_PATH/fullchain.pem" ]; then
        echo "❌ Error: Certificate not found at $CERT_PATH/fullchain.pem"
        exit 1
    fi

    echo "Encoding certificates..."
    CERT_B64=$(sudo base64 -w0 < "$CERT_PATH/fullchain.pem")
    KEY_B64=$(sudo base64 -w0 < "$CERT_PATH/privkey.pem")

    echo "Backing up existing acme.json..."
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

    echo ""
    echo "Step 3: Restarting Traefik..."
    docker compose restart traefik

    echo ""
    echo "Waiting for Traefik to start..."
    sleep 5

    echo ""
    echo "Step 4: Testing SSL certificate..."
    echo ""
    curl -v https://securenexus.net 2>&1 | grep -E "subject:|issuer:" | head -2

    echo ""
    echo "========================================="
    echo "✅ SSL Certificate Installation Complete!"
    echo "========================================="
    echo ""
    echo "Your wildcard certificate covers:"
    echo "  - securenexus.net"
    echo "  - *.securenexus.net (all subdomains)"
    echo ""
    echo "Certificate expires: $(sudo openssl x509 -enddate -noout -in $CERT_PATH/fullchain.pem | cut -d= -f2)"
    echo ""
    echo "Next steps:"
    echo "  1. Clean up TXT records from DNS zone file"
    echo "  2. Test all your services via HTTPS"
    echo "  3. Set up auto-renewal (see CERTBOT_GUIDE.md)"
    echo ""
else
    echo ""
    echo "❌ Certbot failed. Please check the error messages above."
    echo ""
    echo "Common issues:"
    echo "  - TXT records not propagated (wait 30s after adding)"
    echo "  - DNS not responding (check CoreDNS status)"
    echo "  - Rate limit hit (wait 1 hour and try again)"
    echo ""
fi
