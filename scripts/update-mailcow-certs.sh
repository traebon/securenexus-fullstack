#!/bin/bash
# Update Mailcow SSL Certificates from Traefik ACME
# Extracts mail.securenexus.net certificate from Traefik and installs in Mailcow

set -e

ACME_FILE="/home/tristian/securenexus-fullstack/acme/acme.json"
MAILCOW_SSL="/home/tristian/securenexus-fullstack/mail/mailcow-dockerized/data/assets/ssl"
DOMAIN="mail.securenexus.net"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔐 Mailcow Certificate Update${NC}"
echo "================================"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Error: This script must be run as root (sudo)${NC}"
    echo "Usage: sudo ./scripts/update-mailcow-certs.sh"
    exit 1
fi

# Check if acme.json exists
if [ ! -f "$ACME_FILE" ]; then
    echo -e "${RED}❌ Error: ACME file not found: $ACME_FILE${NC}"
    exit 1
fi

# Check if Mailcow SSL directory exists
if [ ! -d "$MAILCOW_SSL" ]; then
    echo -e "${RED}❌ Error: Mailcow SSL directory not found: $MAILCOW_SSL${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 Extracting certificate for: $DOMAIN${NC}"

# Extract certificate and key using jq (try both common ACME formats)
CERT=$(cat "$ACME_FILE" | jq -r ".le.Certificates[]? | select(.domain.main == \"$DOMAIN\") | .certificate" 2>/dev/null | base64 -d 2>/dev/null)
KEY=$(cat "$ACME_FILE" | jq -r ".le.Certificates[]? | select(.domain.main == \"$DOMAIN\") | .key" 2>/dev/null | base64 -d 2>/dev/null)

# Try alternative format if first attempt failed
if [ -z "$CERT" ]; then
    CERT=$(cat "$ACME_FILE" | jq -r ".letsencrypt.Certificates[]? | select(.domain.main == \"$DOMAIN\") | .certificate" 2>/dev/null | base64 -d 2>/dev/null)
    KEY=$(cat "$ACME_FILE" | jq -r ".letsencrypt.Certificates[]? | select(.domain.main == \"$DOMAIN\") | .key" 2>/dev/null | base64 -d 2>/dev/null)
fi

# Check if certificate was found
if [ -z "$CERT" ] || [ -z "$KEY" ]; then
    echo -e "${RED}❌ Error: Certificate for $DOMAIN not found in ACME file${NC}"
    echo ""
    echo "Available certificates:"
    cat "$ACME_FILE" | jq -r '.letsencrypt.Certificates[] | .domain.main'
    echo ""
    echo "Make sure Traefik has generated a certificate for $DOMAIN first."
    exit 1
fi

# Backup existing certificates
echo -e "${YELLOW}📦 Backing up existing certificates...${NC}"
BACKUP_DIR="$MAILCOW_SSL/backup-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp "$MAILCOW_SSL/cert.pem" "$BACKUP_DIR/" 2>/dev/null || true
cp "$MAILCOW_SSL/key.pem" "$BACKUP_DIR/" 2>/dev/null || true
echo "✅ Backup created: $BACKUP_DIR"

# Install new certificates
echo -e "${YELLOW}📝 Installing new certificates...${NC}"
echo "$CERT" > "$MAILCOW_SSL/cert.pem"
echo "$KEY" > "$MAILCOW_SSL/key.pem"

# Set proper permissions
chmod 644 "$MAILCOW_SSL/cert.pem"
chmod 600 "$MAILCOW_SSL/key.pem"
chown tristian:tristian "$MAILCOW_SSL/cert.pem"
chown tristian:tristian "$MAILCOW_SSL/key.pem"

echo "✅ Certificates installed"

# Verify new certificate
echo ""
echo -e "${YELLOW}🔍 Verifying new certificate...${NC}"
openssl x509 -in "$MAILCOW_SSL/cert.pem" -noout -subject -issuer -dates

echo ""
echo -e "${GREEN}✅ Certificates installed successfully!${NC}"
echo ""

# Restart mail services to load new certificates
echo -e "${YELLOW}🔄 Restarting mail services...${NC}"
docker restart mailcowdockerized-dovecot-mailcow-1 mailcowdockerized-postfix-mailcow-1
echo "✅ Mail services restarted"

echo ""
echo -e "${GREEN}✅ Certificate update complete!${NC}"
echo ""
echo -e "${YELLOW}📋 Verification:${NC}"
echo "# Check HTTPS"
echo "curl -I https://mail.securenexus.net"
echo ""
echo "# Check IMAP (port 993)"
echo "echo | openssl s_client -connect mail.securenexus.net:993 -servername mail.securenexus.net 2>/dev/null | openssl x509 -noout -issuer"
echo ""
echo "# Check SMTP (port 587)"
echo "echo | openssl s_client -connect mail.securenexus.net:587 -starttls smtp -servername mail.securenexus.net 2>/dev/null | openssl x509 -noout -issuer"
echo ""
