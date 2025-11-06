#!/bin/bash
#
# Complete Client Onboarding Script
# Creates infrastructure + Guides through ERPNext setup wizard
#
# Usage: ./scripts/onboard-new-client.sh
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Configuration
BASE_DIR="/home/tristian/securenexus-fullstack"
WIZARD_SCRIPT="${BASE_DIR}/scripts/erp-setup-wizard.sh"
PROVISION_SCRIPT="${BASE_DIR}/scripts/provision-client-complete.sh"

# Client data (will be collected)
CLIENT_NAME=""
SUBDOMAIN=""
EMAIL_DOMAIN=""
PLAN="professional"
ERP_SITE=""
ADMIN_PASSWORD=""
EMAIL_PASSWORD=""
MAIN_EMAIL=""

# Progress tracking
PHASE_FILE="/tmp/client-onboarding-phase.txt"
touch "$PHASE_FILE"

# Functions
print_banner() {
    clear
    echo -e "${MAGENTA}${BOLD}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   ██████╗ ██╗   ██╗██████╗ ███╗   ██╗███████╗                ║
║   ██╔══██╗╚██╗ ██╔╝██╔══██╗████╗  ██║██╔════╝                ║
║   ██████╔╝ ╚████╔╝ ██████╔╝██╔██╗ ██║█████╗                  ║
║   ██╔══██╗  ╚██╔╝  ██╔══██╗██║╚██╗██║██╔══╝                  ║
║   ██████╔╝   ██║   ██║  ██║██║ ╚████║███████╗                ║
║   ╚═════╝    ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝                ║
║                                                               ║
║            COMPLETE CLIENT ONBOARDING WIZARD                  ║
║         Infrastructure + Full ERPNext Configuration           ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

print_phase_banner() {
    echo -e "\n${CYAN}${BOLD}"
    echo "═══════════════════════════════════════════════════════════════"
    echo "  $1"
    echo "═══════════════════════════════════════════════════════════════"
    echo -e "${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

save_phase() {
    echo "$1" > "$PHASE_FILE"
}

get_phase() {
    if [ -f "$PHASE_FILE" ]; then
        cat "$PHASE_FILE"
    else
        echo "start"
    fi
}

pause() {
    echo ""
    read -p "Press Enter to continue..." -r
}

# Collect client information
collect_client_info() {
    print_banner
    print_phase_banner "PHASE 1: Client Information Collection"

    echo -e "${BOLD}Let's gather information about the new client.${NC}"
    echo ""

    # Client name
    while [[ -z "$CLIENT_NAME" ]]; do
        read -p "Client Company Name (e.g., 'ACME Corporation'): " CLIENT_NAME
        if [[ -z "$CLIENT_NAME" ]]; then
            print_error "Company name is required"
        fi
    done

    # Subdomain
    while [[ -z "$SUBDOMAIN" ]]; do
        read -p "Subdomain for ERP (e.g., 'acme'): " SUBDOMAIN
        # Validate subdomain format
        if [[ ! "$SUBDOMAIN" =~ ^[a-z0-9-]+$ ]]; then
            print_error "Subdomain must be lowercase letters, numbers, and hyphens only"
            SUBDOMAIN=""
        fi
    done

    # Email domain
    echo ""
    echo -e "${YELLOW}Custom Email Domain:${NC}"
    echo "  • Press Enter to use: byrne-accounts.org"
    echo "  • Or enter custom domain: example.com"
    read -p "Email domain [byrne-accounts.org]: " EMAIL_DOMAIN
    if [[ -z "$EMAIL_DOMAIN" ]]; then
        EMAIL_DOMAIN="byrne-accounts.org"
    fi

    # Subscription plan
    echo ""
    echo -e "${BOLD}Subscription Plan:${NC}"
    echo "  1) Starter   - Basic features"
    echo "  2) Professional - Full features (recommended)"
    echo "  3) Enterprise - Advanced features + priority support"
    read -p "Select plan [1-3] (default: 2): " plan_choice
    case $plan_choice in
        1) PLAN="starter" ;;
        3) PLAN="enterprise" ;;
        *) PLAN="professional" ;;
    esac

    # Calculate URLs and emails
    ERP_SITE="${SUBDOMAIN}.byrne-accounts.org"
    MAIN_EMAIL="${SUBDOMAIN}@${EMAIL_DOMAIN}"

    # Generate secure passwords
    ADMIN_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-20)
    EMAIL_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-20)

    # Confirmation
    clear
    print_banner
    echo -e "${GREEN}${BOLD}Client Information Summary:${NC}"
    echo ""
    echo -e "${BOLD}Company Details:${NC}"
    echo "  Name:          ${CLIENT_NAME}"
    echo "  Subdomain:     ${SUBDOMAIN}"
    echo "  Plan:          ${PLAN}"
    echo ""
    echo -e "${BOLD}Access URLs:${NC}"
    echo "  ERP Site:      https://${ERP_SITE}"
    echo "  POS:           https://${ERP_SITE}/pos"
    echo ""
    echo -e "${BOLD}Email System:${NC}"
    echo "  Domain:        ${EMAIL_DOMAIN}"
    echo "  Main Email:    ${MAIN_EMAIL}"
    echo "  Aliases:       support@, info@, financial@, sales@, accounts@"
    echo ""
    echo -e "${BOLD}Generated Credentials:${NC}"
    echo "  ERP Admin:     Administrator / ${ADMIN_PASSWORD}"
    echo "  Email:         ${MAIN_EMAIL} / ${EMAIL_PASSWORD}"
    echo ""
    echo -e "${YELLOW}${BOLD}⚠️  Important:${NC}"
    echo "  These credentials will be saved securely in: client-credentials/${ERP_SITE}.txt"
    echo ""

    read -p "Is this information correct? [y/N]: " -r confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        print_warning "Cancelled. Run script again to start over."
        rm -f "$PHASE_FILE"
        exit 0
    fi

    save_phase "infrastructure"
}

# Phase 2: Create infrastructure
create_infrastructure() {
    print_banner
    print_phase_banner "PHASE 2: Infrastructure Provisioning"

    echo -e "${BOLD}Creating complete infrastructure for ${CLIENT_NAME}...${NC}"
    echo ""
    echo "This will provision:"
    echo "  ✓ ERPNext site with custom domain"
    echo "  ✓ Database and application stack"
    echo "  ✓ Email domain and mailbox"
    echo "  ✓ Email aliases (support@, info@, etc.)"
    echo "  ✓ Traefik HTTPS routing"
    echo "  ✓ SSL certificates"
    echo "  ✓ POS Awesome installation"
    echo ""

    read -p "Ready to provision infrastructure? [y/N]: " -r confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        print_warning "Skipping infrastructure provisioning"
        save_phase "wizard"
        return
    fi

    echo ""
    print_info "Starting infrastructure provisioning..."
    echo ""

    # Run the provisioning script with collected data
    "$PROVISION_SCRIPT" \
        --name "$CLIENT_NAME" \
        --subdomain "$SUBDOMAIN" \
        --domain "$EMAIL_DOMAIN" \
        --plan "$PLAN" || {
        print_error "Infrastructure provisioning failed!"
        exit 1
    }

    print_success "Infrastructure provisioning complete!"
    save_phase "wizard"
    pause
}

# Phase 3: Launch ERPNext Setup Wizard
launch_erp_wizard() {
    print_banner
    print_phase_banner "PHASE 3: ERPNext Configuration Wizard"

    echo -e "${BOLD}Infrastructure is ready! Now let's configure ERPNext.${NC}"
    echo ""
    echo "The ERPNext Setup Wizard will guide you through:"
    echo ""
    echo -e "${CYAN}Essential Configuration:${NC}"
    echo "  1. Initial ERPNext setup (language, region, modules)"
    echo "  2. Company settings (address, tax IDs, accounts)"
    echo "  3. Chart of Accounts customization"
    echo "  4. Point of Sale (POS) configuration"
    echo "  5. Inventory & warehouse setup"
    echo "  6. Products/services catalog"
    echo "  7. User management & permissions"
    echo "  8. Email integration"
    echo "  9. Print formats & templates"
    echo " 10. Custom branding"
    echo ""
    echo -e "${CYAN}Advanced Configuration (optional):${NC}"
    echo " 11. Advanced accounting"
    echo " 12. HR & payroll"
    echo " 13. CRM & sales pipeline"
    echo " 14. Reports & dashboards"
    echo " 15. Workflow automation"
    echo " 16. System testing"
    echo ""
    echo -e "${BOLD}Client Access Details:${NC}"
    echo "  ERP URL:    https://${ERP_SITE}"
    echo "  Username:   Administrator"
    echo "  Password:   ${ADMIN_PASSWORD}"
    echo ""
    echo -e "${YELLOW}Tip: The wizard tracks your progress and you can resume anytime.${NC}"
    echo ""

    read -p "Launch ERPNext Configuration Wizard? [y/N]: " -r confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        print_warning "Skipping wizard. You can run it later:"
        echo "  $WIZARD_SCRIPT"
        save_phase "complete"
        return
    fi

    echo ""
    print_info "Launching ERPNext Configuration Wizard..."
    sleep 2

    # Create site-specific wizard environment
    export ERP_SITE_BEING_CONFIGURED="$ERP_SITE"
    export ERP_ADMIN_PASSWORD="$ADMIN_PASSWORD"
    export CLIENT_NAME_CONFIGURED="$CLIENT_NAME"

    # Launch the wizard
    "$WIZARD_SCRIPT"

    save_phase "complete"
}

# Phase 4: Final summary and next steps
show_completion_summary() {
    print_banner
    print_phase_banner "CLIENT ONBOARDING COMPLETE! 🎉"

    echo -e "${GREEN}${BOLD}Congratulations! ${CLIENT_NAME} is fully provisioned.${NC}"
    echo ""

    echo -e "${BOLD}═══ Access Information ═══${NC}"
    echo ""
    echo -e "${CYAN}Portal Access:${NC}"
    echo "  URL: https://byrne-accounts.org/portal.html"
    echo "  Select: \"${CLIENT_NAME}\" from dropdown"
    echo ""
    echo -e "${CYAN}ERP System:${NC}"
    echo "  URL: https://${ERP_SITE}"
    echo "  Username: Administrator"
    echo "  Password: ${ADMIN_PASSWORD}"
    echo "  Features: Accounting, Inventory, POS, CRM, HR, Projects"
    echo ""
    echo -e "${CYAN}Point of Sale:${NC}"
    echo "  URL: https://${ERP_SITE}/pos"
    echo "  Login: Same as ERP above"
    echo "  Features: Touch POS, Barcode Scanning, Offline Mode"
    echo ""
    echo -e "${CYAN}Email System:${NC}"
    echo "  Webmail: https://mail.securenexus.net"
    echo "  Email: ${MAIN_EMAIL}"
    echo "  Password: ${EMAIL_PASSWORD}"
    echo ""
    echo "  Available Addresses (all forward to main inbox):"
    echo "    • ${MAIN_EMAIL}"
    echo "    • support@${EMAIL_DOMAIN}"
    echo "    • info@${EMAIL_DOMAIN}"
    echo "    • financial@${EMAIL_DOMAIN}"
    echo "    • sales@${EMAIL_DOMAIN}"
    echo "    • accounts@${EMAIL_DOMAIN}"
    echo ""

    CREDS_FILE="client-credentials/${ERP_SITE}.txt"
    echo -e "${BOLD}═══ Credentials File ═══${NC}"
    echo ""
    echo "  Location: ${GREEN}${CREDS_FILE}${NC}"
    echo "  View: cat ${CREDS_FILE}"
    echo ""

    echo -e "${BOLD}═══ Next Steps ═══${NC}"
    echo ""
    echo -e "${YELLOW}1. Add client to portal dropdown:${NC}"
    echo "   Edit: byrne-website/portal.html"
    echo "   Add: <option value=\"${ERP_SITE}\">${CLIENT_NAME}</option>"
    echo ""
    echo -e "${YELLOW}2. Send welcome email to client:${NC}"
    echo "   • Attach credentials file"
    echo "   • Include quick start guide"
    echo "   • Schedule onboarding call"
    echo ""
    echo -e "${YELLOW}3. Complete ERPNext configuration:${NC}"
    echo "   • Import client's customers"
    echo "   • Import products/services"
    echo "   • Set up custom fields (if needed)"
    echo "   • Configure workflows"
    echo ""
    echo -e "${YELLOW}4. Test all systems:${NC}"
    echo "   ✓ ERP login and navigation"
    echo "   ✓ POS transaction flow"
    echo "   ✓ Email send/receive"
    echo "   ✓ Print invoice PDF"
    echo "   ✓ User permissions"
    echo ""
    echo -e "${YELLOW}5. Client training:${NC}"
    echo "   • Schedule training session"
    echo "   • Provide documentation links"
    echo "   • Set up support channel"
    echo ""

    echo -e "${BOLD}═══ Useful Commands ═══${NC}"
    echo ""
    echo "  View credentials:"
    echo "    cat ${CREDS_FILE}"
    echo ""
    echo "  Restart ERPNext:"
    echo "    docker compose restart erpnext-backend"
    echo ""
    echo "  View ERPNext logs:"
    echo "    docker compose logs -f erpnext-backend"
    echo ""
    echo "  Access ERPNext console:"
    echo "    docker exec -it erpnext-backend bash"
    echo ""
    echo "  Clear cache:"
    echo "    docker exec -it erpnext-backend bench --site ${ERP_SITE} clear-cache"
    echo ""
    echo "  Run wizard again:"
    echo "    ${WIZARD_SCRIPT}"
    echo ""

    echo -e "${GREEN}${BOLD}Client ${CLIENT_NAME} is ready for business! 🚀${NC}"
    echo ""

    # Clean up phase file
    rm -f "$PHASE_FILE"
}

# Main workflow
main() {
    # Check if running from correct directory
    if [ ! -f "compose.yml" ]; then
        print_error "Please run this script from the securenexus-fullstack directory"
        exit 1
    fi

    # Check if required scripts exist
    if [ ! -f "$WIZARD_SCRIPT" ]; then
        print_error "ERPNext wizard not found: $WIZARD_SCRIPT"
        exit 1
    fi

    if [ ! -f "$PROVISION_SCRIPT" ]; then
        print_error "Provisioning script not found: $PROVISION_SCRIPT"
        exit 1
    fi

    # Resume or start fresh
    CURRENT_PHASE=$(get_phase)

    case $CURRENT_PHASE in
        start)
            collect_client_info
            create_infrastructure
            launch_erp_wizard
            show_completion_summary
            ;;
        infrastructure)
            create_infrastructure
            launch_erp_wizard
            show_completion_summary
            ;;
        wizard)
            launch_erp_wizard
            show_completion_summary
            ;;
        complete)
            show_completion_summary
            ;;
        *)
            collect_client_info
            create_infrastructure
            launch_erp_wizard
            show_completion_summary
            ;;
    esac
}

# Run main function
main "$@"
