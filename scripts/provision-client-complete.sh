#!/bin/bash
#
# Complete Client Provisioning Script
# Creates: ERPNext site, Email domain, Main mailbox, Email aliases, Traefik routing, DNS
#
# Usage: ./scripts/provision-client-complete.sh --name "ACME Corp" --subdomain "acme" --domain "acmecorp.com"
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
CLIENT_NAME=""
SUBDOMAIN=""
EMAIL_DOMAIN=""
PLAN="professional"
MAILBOX_QUOTA="10240"  # 10GB in MB
ADMIN_PASSWORD=""
EMAIL_PASSWORD=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --name)
            CLIENT_NAME="$2"
            shift 2
            ;;
        --subdomain)
            SUBDOMAIN="$2"
            shift 2
            ;;
        --domain)
            EMAIL_DOMAIN="$2"
            shift 2
            ;;
        --plan)
            PLAN="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 --name 'Client Name' --subdomain 'subdomain' [--domain 'email-domain.com'] [--plan professional]"
            echo ""
            echo "Examples:"
            echo "  $0 --name 'ACME Corp' --subdomain 'acme' --domain 'acmecorp.com'"
            echo "  $0 --name 'Demo Client' --subdomain 'demo'"
            echo ""
            echo "Options:"
            echo "  --name      Client company name (required)"
            echo "  --subdomain Subdomain for ERP (e.g., 'acme' → acme.byrne-accounts.org)"
            echo "  --domain    Custom email domain (optional, uses @byrne-accounts.org if not specified)"
            echo "  --plan      Subscription plan: starter, professional, enterprise (default: professional)"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Validate required arguments
if [[ -z "$CLIENT_NAME" ]] || [[ -z "$SUBDOMAIN" ]]; then
    echo -e "${RED}Error: --name and --subdomain are required${NC}"
    echo "Run with --help for usage information"
    exit 1
fi

# Use byrne-accounts.org if no custom domain specified
if [[ -z "$EMAIL_DOMAIN" ]]; then
    EMAIL_DOMAIN="byrne-accounts.org"
    echo -e "${YELLOW}No custom email domain specified, using: ${EMAIL_DOMAIN}${NC}"
fi

# Generate secure passwords
ADMIN_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-20)
EMAIL_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-20)

# Construct URLs
ERP_SITE="${SUBDOMAIN}.byrne-accounts.org"
MAIN_EMAIL="${SUBDOMAIN}@${EMAIL_DOMAIN}"

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Byrne Accounts - Complete Client Provisioning${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}Client Details:${NC}"
echo "  Name:          ${CLIENT_NAME}"
echo "  Subdomain:     ${SUBDOMAIN}"
echo "  ERP Site:      https://${ERP_SITE}"
echo "  Email Domain:  ${EMAIL_DOMAIN}"
echo "  Main Email:    ${MAIN_EMAIL}"
echo "  Plan:          ${PLAN}"
echo ""
echo -e "${YELLOW}Generated Credentials:${NC}"
echo "  ERP Admin:     Administrator / ${ADMIN_PASSWORD}"
echo "  Email:         ${MAIN_EMAIL} / ${EMAIL_PASSWORD}"
echo ""
read -p "Continue with provisioning? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Provisioning cancelled."
    exit 0
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Step 1: Creating ERPNext Site${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"

# Get database root password
DB_ROOT_PASS=$(cat secrets/erpnext_db_password.txt)

echo "Creating ERPNext site: ${ERP_SITE}..."
docker exec erpnext-backend bash -c "cd /home/frappe/frappe-bench && \
  bench new-site ${ERP_SITE} \
    --mariadb-root-password '${DB_ROOT_PASS}' \
    --admin-password '${ADMIN_PASSWORD}' \
    --install-app erpnext" || {
    echo -e "${RED}Failed to create ERPNext site${NC}"
    exit 1
}

echo -e "${GREEN}✓ ERPNext site created${NC}"

echo "Installing POS Awesome..."
docker exec erpnext-backend bash -c "cd /home/frappe/frappe-bench && \
  bench --site ${ERP_SITE} install-app posawesome" || {
    echo -e "${RED}Failed to install POS Awesome${NC}"
    exit 1
}

echo -e "${GREEN}✓ POS Awesome installed${NC}"

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Step 1b: ERPNext Configuration${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"

echo ""
echo -e "${YELLOW}The ERPNext site has been created: ${ERP_SITE}${NC}"
echo ""
echo -e "${BLUE}Next: Complete initial setup via web browser${NC}"
echo ""
echo "  URL: ${ERP_URL}"
echo "  Username: Administrator"
echo "  Password: ${ADMIN_PASSWORD}"
echo ""
echo -e "${YELLOW}When you first login, ERPNext will show a setup wizard.${NC}"
echo -e "${YELLOW}Complete this basic wizard (takes 2-3 minutes):${NC}"
echo ""
echo "  • Language: English"
echo "  • Country: United Kingdom"
echo "  • Company Name: ${CLIENT_NAME}"
echo "  • Currency: GBP"
echo "  • Chart of Accounts: United Kingdom"
echo ""
echo -e "${BLUE}After completing the initial wizard, return here.${NC}"
echo ""
read -p "Press Enter after completing the initial setup wizard..." -r

echo ""
echo -e "${GREEN}✓ Initial setup complete${NC}"

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Step 2: Setting Up Email System${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"

# Check if Mailcow API key exists
MAILCOW_API_KEY=""
if [[ -f "secrets/mailcow_api_key.txt" ]]; then
    MAILCOW_API_KEY=$(cat secrets/mailcow_api_key.txt)
else
    echo -e "${YELLOW}Warning: Mailcow API key not found${NC}"
    echo -e "${YELLOW}Please create mailbox and aliases manually:${NC}"
    echo ""
    echo "1. Login to: https://mail.securenexus.net"
    echo "2. Create mailbox: ${MAIN_EMAIL}"
    echo "3. Create aliases (all forward to ${MAIN_EMAIL}):"
    echo "   - support@${EMAIL_DOMAIN}"
    echo "   - info@${EMAIL_DOMAIN}"
    echo "   - financial@${EMAIL_DOMAIN}"
    echo "   - sales@${EMAIL_DOMAIN}"
    echo "   - accounts@${EMAIL_DOMAIN}"
    echo ""
    echo -e "${YELLOW}Skipping email automation...${NC}"
fi

if [[ -n "$MAILCOW_API_KEY" ]]; then
    echo "Creating main mailbox: ${MAIN_EMAIL}..."

    # Extract local part and domain
    LOCAL_PART="${SUBDOMAIN}"

    # Create mailbox via Mailcow API
    MAILBOX_RESPONSE=$(curl -s -X POST "https://mail.securenexus.net/api/v1/add/mailbox" \
      -H "X-API-Key: ${MAILCOW_API_KEY}" \
      -H "Content-Type: application/json" \
      -d "{
        \"local_part\": \"${LOCAL_PART}\",
        \"domain\": \"${EMAIL_DOMAIN}\",
        \"name\": \"${CLIENT_NAME}\",
        \"password\": \"${EMAIL_PASSWORD}\",
        \"password2\": \"${EMAIL_PASSWORD}\",
        \"quota\": \"${MAILBOX_QUOTA}\",
        \"active\": \"1\",
        \"force_pw_update\": \"0\",
        \"sogo_access\": \"1\"
      }")

    if [[ $(echo "$MAILBOX_RESPONSE" | jq -r 'type') == "array" ]]; then
        if [[ $(echo "$MAILBOX_RESPONSE" | jq -r '.[0].type') == "success" ]]; then
            echo -e "${GREEN}✓ Mailbox created: ${MAIN_EMAIL}${NC}"
        else
            echo -e "${YELLOW}Warning: ${MAILBOX_RESPONSE}${NC}"
        fi
    else
        echo -e "${YELLOW}Mailbox may already exist or API error${NC}"
    fi

    # Create email aliases
    echo "Creating email aliases..."
    ALIASES=("support" "info" "financial" "sales" "accounts")

    for ALIAS in "${ALIASES[@]}"; do
        ALIAS_EMAIL="${ALIAS}@${EMAIL_DOMAIN}"

        ALIAS_RESPONSE=$(curl -s -X POST "https://mail.securenexus.net/api/v1/add/alias" \
          -H "X-API-Key: ${MAILCOW_API_KEY}" \
          -H "Content-Type: application/json" \
          -d "{
            \"address\": \"${ALIAS_EMAIL}\",
            \"goto\": \"${MAIN_EMAIL}\",
            \"active\": \"1\"
          }")

        if [[ $(echo "$ALIAS_RESPONSE" | jq -r 'type') == "array" ]]; then
            if [[ $(echo "$ALIAS_RESPONSE" | jq -r '.[0].type') == "success" ]]; then
                echo -e "${GREEN}  ✓ Alias created: ${ALIAS_EMAIL} → ${MAIN_EMAIL}${NC}"
            else
                echo -e "${YELLOW}  Warning: ${ALIAS_RESPONSE}${NC}"
            fi
        fi
    done

    echo -e "${GREEN}✓ Email system configured${NC}"
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Step 3: Configuring Traefik Routing${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"

echo -e "${YELLOW}Adding Traefik labels to compose.yml...${NC}"
echo ""
echo "Please add these labels to erpnext-backend service in compose.yml:"
echo ""
echo "      # Client site: ${ERP_SITE}"
echo "      - traefik.http.routers.erp-${SUBDOMAIN}.rule=Host(\`${ERP_SITE}\`)"
echo "      - traefik.http.routers.erp-${SUBDOMAIN}.entrypoints=websecure"
echo "      - traefik.http.routers.erp-${SUBDOMAIN}.tls.certresolver=le"
echo "      - traefik.http.routers.erp-${SUBDOMAIN}.middlewares=secure-headers@file"
echo "      - traefik.http.routers.erp-${SUBDOMAIN}.service=erp"
echo "      - traefik.http.routers.erp-${SUBDOMAIN}-http.rule=Host(\`${ERP_SITE}\`)"
echo "      - traefik.http.routers.erp-${SUBDOMAIN}-http.entrypoints=web"
echo "      - traefik.http.routers.erp-${SUBDOMAIN}-http.middlewares=redirect-to-https@file"
echo ""
echo -e "${YELLOW}Press Enter after adding labels to compose.yml...${NC}"
read

echo "Restarting ERPNext backend..."
docker compose restart erpnext-backend

echo -e "${GREEN}✓ Traefik routing configured${NC}"

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Step 4: Saving Credentials${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"

# Create client credentials directory
mkdir -p client-credentials

# Save credentials
CREDS_FILE="client-credentials/${ERP_SITE}.txt"
cat > "$CREDS_FILE" <<EOF
═══════════════════════════════════════════════════════════
  ${CLIENT_NAME} - Complete Access Credentials
═══════════════════════════════════════════════════════════

PORTAL ACCESS:
  URL: https://byrne-accounts.org/portal.html
  Select: "${CLIENT_NAME}" from dropdown

ERP SYSTEM:
  URL: https://${ERP_SITE}
  Username: Administrator
  Password: ${ADMIN_PASSWORD}
  Features: Accounting, Inventory, CRM, HR, Projects

POS SYSTEM:
  URL: https://${ERP_SITE}/pos
  Username: Administrator
  Password: ${ADMIN_PASSWORD}
  Features: Touch POS, Barcode Scanning, Offline Mode

EMAIL SYSTEM:
  Webmail: https://mail.securenexus.net
  Main Email: ${MAIN_EMAIL}
  Password: ${EMAIL_PASSWORD}

  Available Addresses (all go to ${MAIN_EMAIL}):
  • ${MAIN_EMAIL} (main inbox)
  • support@${EMAIL_DOMAIN}
  • info@${EMAIL_DOMAIN}
  • financial@${EMAIL_DOMAIN}
  • sales@${EMAIL_DOMAIN}
  • accounts@${EMAIL_DOMAIN}

  Email Client Settings (IMAP/SMTP):
  • IMAP Server: mail.securenexus.net
  • IMAP Port: 993 (SSL/TLS)
  • SMTP Server: mail.securenexus.net
  • SMTP Port: 587 (STARTTLS) or 465 (SSL/TLS)
  • Username: ${MAIN_EMAIL}
  • Password: ${EMAIL_PASSWORD}

SUBSCRIPTION:
  Plan: ${PLAN}
  Created: $(date)
  Database: _${SUBDOMAIN//-/_}_byrne_accounts_org

NOTES:
  • All emails sent to support@, info@, financial@, sales@, or accounts@
    will be delivered to the main inbox: ${MAIN_EMAIL}
  • You can reply FROM any of these addresses in webmail
  • Only ONE inbox to monitor
  • Full calendar and contacts included

SUPPORT:
  Email: support@byrne-accounts.org
  Portal: https://byrne-accounts.org

═══════════════════════════════════════════════════════════
EOF

echo -e "${GREEN}✓ Credentials saved to: ${CREDS_FILE}${NC}"

# Make credentials file read-only for security
chmod 600 "$CREDS_FILE"

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Step 5: Adding to Portal${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"

echo -e "${YELLOW}To add this client to the portal dropdown:${NC}"
echo ""
echo "Edit: byrne-website/portal.html"
echo "Add this line inside the <select> element:"
echo ""
echo "  <option value=\"${ERP_SITE}\">${CLIENT_NAME}</option>"
echo ""

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✓ PROVISIONING COMPLETE!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}Client Successfully Created:${NC}"
echo ""
echo "  Client Name:    ${CLIENT_NAME}"
echo "  ERP Site:       https://${ERP_SITE}"
echo "  POS:            https://${ERP_SITE}/pos"
echo "  Email:          ${MAIN_EMAIL}"
echo "  Aliases:        support@, info@, financial@, sales@, accounts@"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo ""
echo "1. View credentials:"
echo "   cat ${CREDS_FILE}"
echo ""
echo "2. Test ERP access:"
echo "   https://${ERP_SITE}"
echo "   Login: Administrator / ${ADMIN_PASSWORD}"
echo ""
echo "3. Test email:"
echo "   https://mail.securenexus.net"
echo "   Login: ${MAIN_EMAIL} / ${EMAIL_PASSWORD}"
echo ""
echo "4. Send welcome email to client with credentials"
echo ""
echo -e "${GREEN}Ready to onboard client! 🎉${NC}"
echo ""

# Launch interactive setup wizard
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Step 6: Complete ERPNext Configuration${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Now launching the interactive setup wizard...${NC}"
echo ""
echo "The wizard will guide you through configuring:"
echo ""
echo "  ${BOLD}Basic Setup (Essential):${NC}"
echo "    1. Company Settings & Details"
echo "    2. Chart of Accounts Review"
echo "    3. POS Profile Configuration"
echo "    4. Inventory & Stock Settings"
echo "    5. Products/Services Setup"
echo "    6. User Management"
echo "    7. Email Integration"
echo "    8. Print Formats"
echo "    9. Custom Branding"
echo ""
echo "  ${BOLD}Advanced Features (Optional):${NC}"
echo "    10. Advanced Accounting"
echo "    11. HR & Payroll"
echo "    12. CRM & Sales Pipeline"
echo "    13. Reports & Dashboards"
echo "    14. Workflow Automation"
echo "    15. System Testing"
echo ""
echo -e "${BLUE}The wizard is interactive and allows you to:${NC}"
echo "  • Jump to any section (non-linear)"
echo "  • Mark sections as complete"
echo "  • Resume later (progress is saved)"
echo ""
echo -e "${GREEN}Tip: Complete sections 1-9 for a fully functional system${NC}"
echo ""
read -p "Press Enter to launch the wizard..." -r

# Launch wizard for this site
echo ""
./scripts/erp-setup-wizard.sh "${ERP_SITE}"
