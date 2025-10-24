#!/bin/bash
# ERPNext Client Site Provisioning Script
# Usage: ./scripts/provision-client-site.sh client-domain.byrne-accounts.org

set -e

SITE_DOMAIN="$1"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

if [ -z "$SITE_DOMAIN" ]; then
    echo -e "${RED}Error: Site domain is required${NC}"
    echo "Usage: $0 <domain>"
    echo "Example: $0 client1.byrne-accounts.org"
    exit 1
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}ERPNext Client Site Provisioning${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Site Domain: ${GREEN}${SITE_DOMAIN}${NC}"
echo ""

# Generate secure admin password
ADMIN_PASSWORD=$(openssl rand -base64 32)

# Get database root password from secrets
if [ ! -f "secrets/erpnext_db_password.txt" ]; then
    echo -e "${RED}Error: Database password not found in secrets/erpnext_db_password.txt${NC}"
    exit 1
fi
DB_ROOT_PASS=$(cat secrets/erpnext_db_password.txt)

# Check if site already exists
if docker exec erpnext-backend bash -c "cd /home/frappe/frappe-bench && ls sites/ | grep -q ^${SITE_DOMAIN}$"; then
    echo -e "${RED}Error: Site already exists!${NC}"
    exit 1
fi

# Create the site
echo -e "${YELLOW}Creating site...${NC}"
docker exec erpnext-backend bash -c "cd /home/frappe/frappe-bench && \
  bench new-site ${SITE_DOMAIN} \
    --mariadb-root-password '${DB_ROOT_PASS}' \
    --admin-password '${ADMIN_PASSWORD}' \
    --no-mariadb-socket \
    --install-app erpnext"

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to create site${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Site created successfully${NC}"

# Install POS Awesome
echo -e "${YELLOW}Installing POS Awesome...${NC}"
docker exec erpnext-backend bash -c "cd /home/frappe/frappe-bench && \
  bench --site ${SITE_DOMAIN} install-app posawesome" 2>/dev/null || echo "POS Awesome not available (optional)"

# Save credentials
CRED_DIR="client-credentials"
mkdir -p "$CRED_DIR"
CRED_FILE="${CRED_DIR}/${SITE_DOMAIN}.txt"

cat > "$CRED_FILE" <<EOF
=====================================
ERPNext Client Site Credentials
=====================================

Site URL: https://${SITE_DOMAIN}
Username: Administrator
Password: ${ADMIN_PASSWORD}

Created: $(date)
Database: ${SITE_DOMAIN//./_}

=====================================
IMPORTANT SECURITY NOTES
=====================================
1. Change the Administrator password after first login
2. Create a separate admin user for the client
3. Disable the default Administrator account
4. Store this file securely and delete after handoff

EOF

chmod 600 "$CRED_FILE"

echo -e "${GREEN}✅ POS Awesome installed${NC}"
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Site provisioning completed!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "📝 Credentials saved to: ${GREEN}${CRED_FILE}${NC}"
echo ""
echo -e "${YELLOW}⚠️  Next Steps:${NC}"
echo ""
echo -e "1. ${BLUE}Add DNS Record:${NC}"
echo "   ${SITE_DOMAIN} → $(curl -s ifconfig.me 2>/dev/null || echo 'YOUR_SERVER_IP')"
echo ""
echo -e "2. ${BLUE}Add Traefik Labels to compose.yml:${NC}"
echo "   Edit compose.yml and add routing for ${SITE_DOMAIN}"
echo "   See: docs/ERPNEXT_MULTI_COMPANY_AND_MULTISITE.md (Part 2, Step 3)"
echo ""
echo -e "3. ${BLUE}Restart Traefik:${NC}"
echo "   docker compose restart traefik erpnext-backend"
echo ""
echo -e "4. ${BLUE}Access Site:${NC}"
echo "   https://${SITE_DOMAIN}"
echo ""
echo -e "5. ${BLUE}Send Credentials to Client:${NC}"
echo "   cat ${CRED_FILE}"
echo ""
echo -e "${GREEN}Done! 🚀${NC}"
