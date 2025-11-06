#!/bin/bash
# ERPNext Interactive Setup Wizard
# Comprehensive guided setup for all ERPNext features

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Configuration
# Accept site as parameter, default to main site
SITE="${1:-erp.byrne-accounts.org}"
ERP_URL="https://$SITE"

# Try to find credentials file for this site
if [[ -f "/home/tristian/securenexus-fullstack/client-credentials/${SITE}.txt" ]]; then
    ADMIN_PASSWORD=$(grep "Password:" "/home/tristian/securenexus-fullstack/client-credentials/${SITE}.txt" | head -1 | awk '{print $NF}')
else
    ADMIN_PASSWORD_FILE="/home/tristian/securenexus-fullstack/secrets/erpnext_admin_password.txt"
    if [[ -f "$ADMIN_PASSWORD_FILE" ]]; then
        ADMIN_PASSWORD=$(cat "$ADMIN_PASSWORD_FILE")
    else
        ADMIN_PASSWORD="(check credentials file)"
    fi
fi

# Progress tracking file (site-specific)
PROGRESS_FILE="/tmp/erp-wizard-progress-${SITE//\./_}.txt"
touch "$PROGRESS_FILE"

# Functions
print_header() {
    clear
    echo -e "${BLUE}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                                                          ║"
    echo "║        ERPNext Complete Setup Wizard                     ║"
    echo "║        Professional Configuration Assistant              ║"
    echo "║                                                          ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_section() {
    echo -e "\n${BLUE}${BOLD}═══ $1 ═══${NC}\n"
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

mark_complete() {
    echo "$1" >> "$PROGRESS_FILE"
    sort -u "$PROGRESS_FILE" -o "$PROGRESS_FILE"
}

is_complete() {
    grep -q "^$1$" "$PROGRESS_FILE" 2>/dev/null && return 0 || return 1
}

get_completion_status() {
    if is_complete "$1"; then
        echo -e "${GREEN}[DONE]${NC}"
    else
        echo -e "${YELLOW}[TODO]${NC}"
    fi
}

pause() {
    echo ""
    read -p "Press Enter to continue..." -r
}

# Main menu
show_main_menu() {
    while true; do
        print_header
        echo -e "${BOLD}Setup Progress:${NC}"
        echo ""
        echo "  1. $(get_completion_status 'initial-wizard') Initial ERPNext Setup Wizard"
        echo "  2. $(get_completion_status 'company-settings') Company Settings & Configuration"
        echo "  3. $(get_completion_status 'chart-of-accounts') Chart of Accounts Setup"
        echo "  4. $(get_completion_status 'pos-profile') Point of Sale (POS) Configuration"
        echo "  5. $(get_completion_status 'inventory') Inventory & Stock Management"
        echo "  6. $(get_completion_status 'items') Products/Services & Price Lists"
        echo "  7. $(get_completion_status 'users') User Management & Permissions"
        echo "  8. $(get_completion_status 'email') Email Integration Setup"
        echo "  9. $(get_completion_status 'printing') Print Formats & Templates"
        echo " 10. $(get_completion_status 'branding') Custom Branding & Themes"
        echo " 11. $(get_completion_status 'advanced-accounting') Advanced Accounting Settings"
        echo " 12. $(get_completion_status 'hr-settings') HR & Payroll Configuration"
        echo " 13. $(get_completion_status 'crm-settings') CRM & Sales Pipeline"
        echo " 14. $(get_completion_status 'reports') Reports & Dashboards"
        echo " 15. $(get_completion_status 'automation') Workflow & Automation"
        echo " 16. $(get_completion_status 'testing') Testing & Verification"
        echo ""
        echo "  A. Advanced Settings Menu"
        echo "  S. Show System Information"
        echo "  R. Reset Progress"
        echo "  Q. Quit"
        echo ""

        read -p "Select option [1-16, A, S, R, Q]: " choice

        case $choice in
            1) initial_wizard_guide ;;
            2) company_settings_guide ;;
            3) chart_of_accounts_guide ;;
            4) pos_configuration_guide ;;
            5) inventory_guide ;;
            6) items_guide ;;
            7) user_management_guide ;;
            8) email_integration_guide ;;
            9) print_formats_guide ;;
            10) branding_guide ;;
            11) advanced_accounting_guide ;;
            12) hr_settings_guide ;;
            13) crm_settings_guide ;;
            14) reports_dashboards_guide ;;
            15) automation_guide ;;
            16) testing_verification ;;
            [Aa]) advanced_settings_menu ;;
            [Ss]) show_system_info ;;
            [Rr]) reset_progress ;;
            [Qq]) exit 0 ;;
            *) print_error "Invalid option" ; sleep 1 ;;
        esac
    done
}

# 1. Initial Wizard Guide
initial_wizard_guide() {
    print_header
    print_section "Initial ERPNext Setup Wizard"

    echo "This guide will walk you through the first-time setup of ERPNext."
    echo ""
    print_info "URL: ${BOLD}$ERP_URL${NC}"
    print_info "Username: ${BOLD}Administrator${NC}"

    if [ -f "$ADMIN_PASSWORD_FILE" ]; then
        ADMIN_PASS=$(cat "$ADMIN_PASSWORD_FILE")
        print_info "Password: ${BOLD}$ADMIN_PASS${NC}"
    else
        print_warning "Password file not found!"
    fi

    echo ""
    echo "═══ Step-by-Step Instructions ═══"
    echo ""
    echo "1. ${BOLD}Open ERPNext in your browser:${NC}"
    echo "   → $ERP_URL"
    echo ""
    echo "2. ${BOLD}Login with Administrator credentials${NC}"
    echo "   (see above for password)"
    echo ""
    echo "3. ${BOLD}Language & Region${NC}"
    echo "   → Language: English (United Kingdom)"
    echo "   → Country: United Kingdom"
    echo "   → Timezone: Europe/London"
    echo "   → Currency: GBP (£)"
    echo ""
    echo "4. ${BOLD}Company Information${NC}"
    echo "   → Company Name: [Your Company Name]"
    echo "   → Abbreviation: [2-3 letter code, e.g., 'BA']"
    echo "   → Default Currency: GBP"
    echo "   → Fiscal Year: April 1 to March 31 (UK tax year)"
    echo "   → Domain: Services (or appropriate for your business)"
    echo ""
    echo "5. ${BOLD}Products/Services${NC}"
    echo "   → Select 'Services' or add your product categories"
    echo "   → You can add more later"
    echo ""
    echo "6. ${BOLD}Select Modules${NC}"
    echo "   Recommended modules:"
    echo "   ✓ Accounting (essential)"
    echo "   ✓ Selling (for invoices and POS)"
    echo "   ✓ Buying (if you purchase supplies)"
    echo "   ✓ Stock (for inventory)"
    echo "   ✓ CRM (customer management)"
    echo "   ✓ HR (if managing employees)"
    echo ""
    echo "7. ${BOLD}Add Users${NC}"
    echo "   → Skip for now (we'll add users later in section 7)"
    echo ""
    echo "8. ${BOLD}Brand & Logo${NC}"
    echo "   → Upload your logo (or skip, we'll customize in section 10)"
    echo "   → Choose brand color"
    echo ""
    echo "9. ${BOLD}Complete Setup${NC}"
    echo "   → Review all settings"
    echo "   → Click 'Complete Setup'"
    echo "   → Wait 2-3 minutes for initialization"
    echo ""

    print_warning "Have you completed the initial setup wizard in ERPNext?"
    read -p "Mark as complete? [y/N]: " -r confirm

    if [[ $confirm =~ ^[Yy]$ ]]; then
        mark_complete 'initial-wizard'
        print_success "Initial wizard marked as complete!"
    fi

    pause
}

# 2. Company Settings Guide
company_settings_guide() {
    print_header
    print_section "Company Settings & Configuration"

    echo "Configure detailed company information and defaults."
    echo ""
    echo "═══ Access Company Settings ═══"
    echo ""
    echo "1. In ERPNext, press ${BOLD}Ctrl+K${NC} (or Cmd+K on Mac)"
    echo "2. Search for: ${BOLD}Company${NC}"
    echo "3. Select your company from the list"
    echo ""
    echo "═══ Essential Settings ═══"
    echo ""
    echo "${BOLD}Company Details:${NC}"
    echo "  • Company Name: Full legal name"
    echo "  • Abbr: 2-3 letter abbreviation (cannot change later!)"
    echo "  • Default Currency: GBP"
    echo "  • Domain: Services/Manufacturing/Retail"
    echo ""
    echo "${BOLD}Contact Information:${NC}"
    echo "  • Company Email: info@yourcompany.com"
    echo "  • Phone: +44 ..."
    echo "  • Website: https://yourcompany.com"
    echo "  • Mobile No: (optional)"
    echo ""
    echo "${BOLD}Address Details:${NC}"
    echo "  1. Click 'New Address' in Addresses section"
    echo "  2. Fill in:"
    echo "     - Address Line 1: Street address"
    echo "     - Address Line 2: Suite/building (optional)"
    echo "     - City/Town"
    echo "     - County"
    echo "     - Postcode"
    echo "     - Country: United Kingdom"
    echo "  3. Check 'Is Primary Address'"
    echo "  4. Save"
    echo ""
    echo "${BOLD}Tax Settings:${NC}"
    echo "  • Default Tax Account: Select VAT account"
    echo "  • Tax ID: Your VAT number (if applicable)"
    echo "  • Registration Number: Companies House number"
    echo ""
    echo "${BOLD}Default Accounts (Important!):${NC}"
    echo "  • Default Bank Account: Select main bank"
    echo "  • Default Cash Account: Select cash account"
    echo "  • Default Receivable Account: Debtors"
    echo "  • Default Payable Account: Creditors"
    echo "  • Default Income Account: Sales"
    echo "  • Default Expense Account: Cost of Goods Sold"
    echo "  • Round Off Account: Round Off"
    echo "  • Round Off Cost Center: Main"
    echo ""
    echo "${BOLD}Cost Centers:${NC}"
    echo "  • Default Cost Center: Main"
    echo "  • (You can create departments later)"
    echo ""
    echo "${BOLD}Letterhead:${NC}"
    echo "  1. Create a new Letterhead:"
    echo "     - Press Ctrl+K, search 'Letterhead'"
    echo "     - Click '+ New'"
    echo "     - Name: Company Letterhead"
    echo "     - Upload header image (logo + company details)"
    echo "     - Set as default"
    echo ""

    print_info "After configuring, click ${BOLD}Save${NC} at the top"
    echo ""

    read -p "Mark company settings as complete? [y/N]: " -r confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        mark_complete 'company-settings'
        print_success "Company settings marked complete!"
    fi

    pause
}

# 3. Chart of Accounts Guide
chart_of_accounts_guide() {
    print_header
    print_section "Chart of Accounts Setup"

    echo "Review and customize your accounting structure."
    echo ""
    echo "═══ Access Chart of Accounts ═══"
    echo ""
    echo "1. Press ${BOLD}Ctrl+K${NC}"
    echo "2. Search: ${BOLD}Chart of Accounts${NC}"
    echo "3. Select your company"
    echo ""
    echo "═══ Default Structure (UK) ═══"
    echo ""
    echo "The system creates a default UK chart of accounts:"
    echo ""
    echo "  📁 Assets"
    echo "     └─ Current Assets"
    echo "        ├─ Bank Accounts"
    echo "        ├─ Cash in Hand"
    echo "        ├─ Debtors"
    echo "        └─ Stock Assets"
    echo "     └─ Fixed Assets"
    echo "        ├─ Plant & Machinery"
    echo "        └─ Office Equipment"
    echo ""
    echo "  📁 Liabilities"
    echo "     └─ Current Liabilities"
    echo "        ├─ Creditors"
    echo "        ├─ VAT Payable"
    echo "        └─ Loans & Advances"
    echo ""
    echo "  📁 Income"
    echo "     ├─ Direct Income (Sales)"
    echo "     └─ Indirect Income (Other)"
    echo ""
    echo "  📁 Expenses"
    echo "     ├─ Direct Expenses (COGS)"
    echo "     └─ Indirect Expenses"
    echo "        ├─ Administrative"
    echo "        ├─ Marketing"
    echo "        ├─ Utilities"
    echo "        └─ Salaries"
    echo ""
    echo "═══ Adding Custom Accounts ═══"
    echo ""
    echo "To add a new account:"
    echo "  1. Click on parent account (where you want to add)"
    echo "  2. Click 'Add Child' button"
    echo "  3. Enter:"
    echo "     - Account Name: e.g., 'Cloud Services Expense'"
    echo "     - Account Type: Select appropriate type"
    echo "     - Tax Rate: If applicable"
    echo "  4. Click 'Create'"
    echo ""
    echo "═══ Common Accounts to Add ═══"
    echo ""
    echo "Under ${BOLD}Expenses > Indirect Expenses${NC}:"
    echo "  • Software Subscriptions"
    echo "  • Professional Fees"
    echo "  • Bank Charges"
    echo "  • Insurance"
    echo "  • Travel & Accommodation"
    echo "  • Postage & Courier"
    echo "  • Office Supplies"
    echo ""
    echo "Under ${BOLD}Income > Direct Income${NC}:"
    echo "  • Consulting Services"
    echo "  • Product Sales"
    echo "  • Support Services"
    echo ""

    print_info "Tip: You can always add accounts later as needed"
    echo ""

    read -p "Mark chart of accounts as reviewed? [y/N]: " -r confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        mark_complete 'chart-of-accounts'
        print_success "Chart of accounts marked complete!"
    fi

    pause
}

# 4. POS Configuration Guide
pos_configuration_guide() {
    print_header
    print_section "Point of Sale (POS) Configuration"

    echo "Set up POS Awesome for retail/counter sales."
    echo ""
    echo "═══ Step 1: Create Warehouse ═══"
    echo ""
    echo "1. Press ${BOLD}Ctrl+K${NC}, search: ${BOLD}Warehouse${NC}"
    echo "2. Click ${BOLD}+ New${NC}"
    echo "3. Fill in:"
    echo "   - Warehouse Name: 'Main Store' or 'Retail Counter'"
    echo "   - Company: Select your company"
    echo "   - Is Group: No (uncheck)"
    echo "4. Save"
    echo ""
    echo "═══ Step 2: Create POS Profile ═══"
    echo ""
    echo "1. Press ${BOLD}Ctrl+K${NC}, search: ${BOLD}POS Profile${NC}"
    echo "2. Click ${BOLD}+ New${NC}"
    echo ""
    echo "${BOLD}Basic Settings:${NC}"
    echo "  • Profile Name: 'Main Store POS'"
    echo "  • Company: Your company"
    echo "  • Customer: Select default customer or create 'Walk-in Customer'"
    echo "  • Currency: GBP"
    echo "  • Country: United Kingdom"
    echo ""
    echo "${BOLD}Warehouse Settings:${NC}"
    echo "  • Warehouse: Select warehouse created above"
    echo ""
    echo "${BOLD}Accounting:${NC}"
    echo "  • Income Account: Sales"
    echo "  • Expense Account: Cost of Goods Sold"
    echo "  • Cost Center: Main"
    echo ""
    echo "${BOLD}Payment Methods Section:${NC}"
    echo "  Click 'Add Row' for each payment method:"
    echo ""
    echo "  Row 1 - Cash:"
    echo "    • Mode of Payment: Cash"
    echo "    • Default: Yes (check)"
    echo "    • Account: Cash - [Your Company]"
    echo ""
    echo "  Row 2 - Card:"
    echo "    • Mode of Payment: Credit Card"
    echo "    • Default: No"
    echo "    • Account: Bank - [Your Company]"
    echo ""
    echo "  Row 3 - Bank Transfer:"
    echo "    • Mode of Payment: Bank Transfer"
    echo "    • Default: No"
    echo "    • Account: Bank - [Your Company]"
    echo ""
    echo "${BOLD}POS Awesome Settings:${NC}"
    echo "  • Use POS Awesome: Yes (check)"
    echo "  • Hide Closing Dialog: No"
    echo "  • Show Item Stock: Yes (recommended)"
    echo "  • Allow Delete: No (for better audit trail)"
    echo "  • Allow User Edit Rate: Yes (if you allow discounts)"
    echo "  • Allow User Edit Discount: Yes"
    echo ""
    echo "${BOLD}Print Settings:${NC}"
    echo "  • Print Format: Point of Sale (or custom format)"
    echo "  • Letter Head: Your company letterhead"
    echo "  • Auto Print: No (optional)"
    echo "  • Print After Submit: Yes (recommended)"
    echo ""
    echo "3. Click ${BOLD}Save${NC}"
    echo ""
    echo "═══ Step 3: Create Walk-in Customer (if needed) ═══"
    echo ""
    echo "1. Press Ctrl+K, search: ${BOLD}Customer${NC}"
    echo "2. Click + New"
    echo "3. Fill in:"
    echo "   - Customer Name: 'Walk-in Customer'"
    echo "   - Customer Type: Individual"
    echo "   - Customer Group: Individual"
    echo "   - Territory: Select your territory"
    echo "4. Save"
    echo ""
    echo "═══ Step 4: Test POS ═══"
    echo ""
    echo "1. Navigate to: ${BOLD}https://pos.byrne-accounts.org${NC}"
    echo "2. Login with your credentials"
    echo "3. Select POS Profile: 'Main Store POS'"
    echo "4. Test adding items and checkout"
    echo ""

    read -p "Mark POS configuration as complete? [y/N]: " -r confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        mark_complete 'pos-profile'
        print_success "POS configuration marked complete!"
    fi

    pause
}

# 5. Inventory & Stock Management
inventory_guide() {
    print_header
    print_section "Inventory & Stock Management"

    echo "Configure warehouses, stock settings, and inventory rules."
    echo ""
    echo "═══ Stock Settings ═══"
    echo ""
    echo "1. Press ${BOLD}Ctrl+K${NC}, search: ${BOLD}Stock Settings${NC}"
    echo "2. Configure:"
    echo ""
    echo "${BOLD}General Settings:${NC}"
    echo "  • Item Naming By: Item Code (or Item Name)"
    echo "  • Default Warehouse: Main Store"
    echo "  • Default Unit of Measure: Nos (Numbers)"
    echo "  • Allow Negative Stock: No (recommended)"
    echo "  • Auto Insert Price List Rate: Yes"
    echo ""
    echo "${BOLD}Stock Ledger:${NC}"
    echo "  • Freeze Stock Entries: (optional - for closing books)"
    echo "  • Frozen Accounts Modifier: (user who can modify)"
    echo ""
    echo "${BOLD}Batch & Serial Numbers:${NC}"
    echo "  • Naming Series for Batches: BATCH-.####"
    echo "  • Naming Series for Serial Nos: SERIAL-.####"
    echo ""
    echo "3. Save"
    echo ""
    echo "═══ Warehouse Management ═══"
    echo ""
    echo "Create multiple warehouses if needed:"
    echo ""
    echo "1. Press Ctrl+K, search: ${BOLD}Warehouse${NC}"
    echo "2. Create warehouses:"
    echo "   • Main Store (already created)"
    echo "   • Damaged Stock"
    echo "   • Returns"
    echo "   • Work in Progress (if manufacturing)"
    echo ""
    echo "═══ Item Groups ═══"
    echo ""
    echo "Organize products into categories:"
    echo ""
    echo "1. Press Ctrl+K, search: ${BOLD}Item Group${NC}"
    echo "2. Default groups exist, add custom ones:"
    echo "   Examples:"
    echo "   • Office Supplies"
    echo "   • Electronics"
    echo "   • Services"
    echo "   • Food & Beverage"
    echo ""
    echo "═══ Stock Reconciliation ═══"
    echo ""
    echo "For initial stock entry:"
    echo ""
    echo "1. Press Ctrl+K, search: ${BOLD}Stock Reconciliation${NC}"
    echo "2. Click + New"
    echo "3. Set Purpose: 'Opening Stock'"
    echo "4. Add items with quantities"
    echo "5. Set Expense Account: 'Stock Adjustment'"
    echo "6. Submit"
    echo ""
    echo "═══ Stock Levels & Reorder ═══"
    echo ""
    echo "Set reorder levels for items:"
    echo ""
    echo "1. Open any Item"
    echo "2. Go to 'Reorder' section"
    echo "3. Add row:"
    echo "   - Warehouse: Main Store"
    echo "   - Reorder Level: 10 (minimum stock)"
    echo "   - Reorder Qty: 50 (quantity to reorder)"
    echo "   - Material Request Type: Purchase"
    echo ""

    read -p "Mark inventory setup as complete? [y/N]: " -r confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        mark_complete 'inventory'
        print_success "Inventory setup marked complete!"
    fi

    pause
}

# 6. Products/Services & Price Lists
items_guide() {
    print_header
    print_section "Products/Services & Price Lists"

    echo "Add your sellable items and configure pricing."
    echo ""
    echo "═══ Creating an Item (Product/Service) ═══"
    echo ""
    echo "1. Press ${BOLD}Ctrl+K${NC}, search: ${BOLD}Item${NC}"
    echo "2. Click ${BOLD}+ New${NC}"
    echo ""
    echo "${BOLD}Basic Information:${NC}"
    echo "  • Item Code: SKU or unique code (e.g., 'PROD-001')"
    echo "  • Item Name: Display name"
    echo "  • Item Group: Select category"
    echo "  • Default Unit of Measure: Nos/Kg/Meter/etc."
    echo "  • Maintain Stock: Yes (if physical product)"
    echo ""
    echo "${BOLD}Sales & Purchase:${NC}"
    echo "  • Standard Selling Rate: £XX.XX (retail price)"
    echo "  • Standard Buying Rate: £XX.XX (cost price)"
    echo "  • Default Supplier: (if applicable)"
    echo "  • Valuation Method: FIFO/Moving Average"
    echo ""
    echo "${BOLD}Tax Settings:${NC}"
    echo "  • Is Sales Item: Yes"
    echo "  • Is Purchase Item: Yes (if you buy it)"
    echo "  • Is Stock Item: Yes/No"
    echo "  • Include in Gross: Yes"
    echo "  • Item Tax Template: VAT 20% (or appropriate)"
    echo ""
    echo "${BOLD}Inventory Settings:${NC}"
    echo "  • Default Warehouse: Main Store"
    echo "  • Shelf Life in Days: (optional)"
    echo "  • Has Batch No: No (unless tracking batches)"
    echo "  • Has Serial No: No (unless tracking serials)"
    echo "  • Warranty Period: (optional, in days)"
    echo ""
    echo "${BOLD}Accounting:${NC}"
    echo "  • Default Income Account: Sales"
    echo "  • Default Expense Account: Cost of Goods Sold"
    echo ""
    echo "${BOLD}Website & E-commerce:${NC}"
    echo "  • Show in Website: Yes (if selling online)"
    echo "  • Website Image: Upload product image"
    echo "  • Description: Full product description"
    echo ""
    echo "3. Save"
    echo ""
    echo "═══ Price Lists ═══"
    echo ""
    echo "Create different price lists for different customer types:"
    echo ""
    echo "1. Press Ctrl+K, search: ${BOLD}Price List${NC}"
    echo "2. Default lists:"
    echo "   • Standard Selling: Regular retail prices"
    echo "   • Standard Buying: Purchase prices"
    echo ""
    echo "Create custom price lists:"
    echo ""
    echo "Example - Wholesale Price List:"
    echo "  • Click + New"
    echo "  • Price List Name: 'Wholesale'"
    echo "  • Currency: GBP"
    echo "  • Buying/Selling: Selling"
    echo "  • Save"
    echo ""
    echo "═══ Item Prices ═══"
    echo ""
    echo "Set item prices for different price lists:"
    echo ""
    echo "1. Press Ctrl+K, search: ${BOLD}Item Price${NC}"
    echo "2. Click + New"
    echo "3. Fill in:"
    echo "   - Item Code: Select item"
    echo "   - Price List: Wholesale"
    echo "   - Rate: £XX.XX (wholesale price)"
    echo "   - Currency: GBP"
    echo "4. Save"
    echo ""
    echo "═══ Bulk Import Items ═══"
    echo ""
    echo "For many items, use data import:"
    echo ""
    echo "1. Press Ctrl+K, search: ${BOLD}Data Import${NC}"
    echo "2. Click + New"
    echo "3. Import Type: Insert New Records"
    echo "4. Document Type: Item"
    echo "5. Download Template"
    echo "6. Fill in Excel/CSV"
    echo "7. Upload and import"
    echo ""
    echo "═══ Item Variants ═══"
    echo ""
    echo "For products with sizes/colors:"
    echo ""
    echo "1. Create Template Item (e.g., 'T-Shirt')"
    echo "2. Check 'Has Variants'"
    echo "3. Add Attributes:"
    echo "   - Size: S, M, L, XL"
    echo "   - Color: Red, Blue, Green"
    echo "4. System generates variants:"
    echo "   - T-Shirt-S-Red"
    echo "   - T-Shirt-M-Blue"
    echo "   - etc."
    echo ""

    read -p "Mark items & pricing as complete? [y/N]: " -r confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        mark_complete 'items'
        print_success "Items & pricing marked complete!"
    fi

    pause
}

# 7. User Management Guide
user_management_guide() {
    print_header
    print_section "User Management & Permissions"

    echo "Add users and configure their access levels."
    echo ""
    echo "═══ Creating Users ═══"
    echo ""
    echo "1. Press ${BOLD}Ctrl+K${NC}, search: ${BOLD}User${NC}"
    echo "2. Click ${BOLD}+ New${NC}"
    echo ""
    echo "${BOLD}User Details:${NC}"
    echo "  • Email: user@yourcompany.com (used as username)"
    echo "  • First Name: John"
    echo "  • Last Name: Doe"
    echo "  • Send Welcome Email: Yes"
    echo "  • Language: English (United Kingdom)"
    echo "  • Time Zone: Europe/London"
    echo ""
    echo "${BOLD}Roles:${NC}"
    echo ""
    echo "Common role combinations:"
    echo ""
    echo "${BOLD}1. POS Cashier:${NC}"
    echo "   ✓ Sales User"
    echo "   ✓ POS User"
    echo "   ✓ Item Manager (view only)"
    echo ""
    echo "${BOLD}2. Accountant:${NC}"
    echo "   ✓ Accounts User"
    echo "   ✓ Accounts Manager"
    echo "   ✓ Sales User (read)"
    echo "   ✓ Purchase User (read)"
    echo ""
    echo "${BOLD}3. Store Manager:${NC}"
    echo "   ✓ Sales User"
    echo "   ✓ Sales Manager"
    echo "   ✓ Stock User"
    echo "   ✓ Stock Manager"
    echo "   ✓ Item Manager"
    echo "   ✓ POS User"
    echo ""
    echo "${BOLD}4. Purchase Officer:${NC}"
    echo "   ✓ Purchase User"
    echo "   ✓ Purchase Manager"
    echo "   ✓ Stock User"
    echo ""
    echo "${BOLD}5. HR Manager:${NC}"
    echo "   ✓ HR User"
    echo "   ✓ HR Manager"
    echo "   ✓ Employee"
    echo ""
    echo "${BOLD}6. Full Admin:${NC}"
    echo "   ✓ System Manager"
    echo "   (Has access to everything)"
    echo ""
    echo "═══ User Permissions ═══"
    echo ""
    echo "Restrict users to specific data:"
    echo ""
    echo "1. In User form, go to 'User Permissions' section"
    echo "2. Add restrictions:"
    echo "   Example: Restrict to specific warehouse"
    echo "   • Document Type: Warehouse"
    echo "   • Name: Main Store"
    echo "   • Apply To All: Check (applies to all docs)"
    echo ""
    echo "Common restrictions:"
    echo "  • Warehouse (limit to specific store)"
    echo "  • Company (in multi-company setup)"
    echo "  • Cost Center (department access)"
    echo "  • Customer Group (territory limits)"
    echo ""
    echo "═══ Role Permissions Manager ═══"
    echo ""
    echo "Customize what each role can do:"
    echo ""
    echo "1. Press Ctrl+K, search: ${BOLD}Role Permissions Manager${NC}"
    echo "2. Select Role: POS User"
    echo "3. Select Document Type: Sales Invoice"
    echo "4. Set permissions:"
    echo "   • Level 0 (no restrictions):"
    echo "     ✓ Read, Write, Create, Submit"
    echo "     ✗ Cancel, Amend, Delete"
    echo ""
    echo "═══ Password Policy ═══"
    echo ""
    echo "1. Press Ctrl+K, search: ${BOLD}System Settings${NC}"
    echo "2. Security section:"
    echo "   • Enable Password Policy: Yes"
    echo "   • Minimum Password Length: 8"
    echo "   • Require Password Change: 90 days"
    echo "   • Session Expiry: 240 hours"
    echo "   • Session Expiry Mobile: 720 hours"
    echo ""
    echo "═══ Two-Factor Authentication ═══"
    echo ""
    echo "Enable 2FA for users:"
    echo ""
    echo "1. Users can enable from: User menu > My Settings"
    echo "2. Two Factor Auth: OTP App/SMS/Email"
    echo "3. Scan QR code with authenticator app"
    echo ""

    read -p "Mark user management as complete? [y/N]: " -r confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        mark_complete 'users'
        print_success "User management marked complete!"
    fi

    pause
}

# 8. Email Integration Guide
email_integration_guide() {
    print_header
    print_section "Email Integration Setup"

    echo "Configure email accounts for sending and receiving."
    echo ""
    echo "═══ Email Account Setup ═══"
    echo ""
    echo "1. Press ${BOLD}Ctrl+K${NC}, search: ${BOLD}Email Account${NC}"
    echo "2. Click ${BOLD}+ New${NC}"
    echo ""
    echo "${BOLD}For Mailcow Integration:${NC}"
    echo ""
    echo "Outgoing (SMTP):"
    echo "  • Email Address: noreply@byrne-accounts.org"
    echo "  • Email Account Name: Company Email"
    echo "  • Domain: byrne-accounts.org"
    echo "  • Password: (from Mailcow)"
    echo "  • SMTP Server: mail.securenexus.net"
    echo "  • Use TLS: Yes"
    echo "  • Port: 587"
    echo "  • Default Outgoing: Yes (check)"
    echo ""
    echo "Incoming (IMAP) - Optional:"
    echo "  • Enable Incoming: Yes"
    echo "  • Email Server: mail.securenexus.net"
    echo "  • Use IMAP: Yes"
    echo "  • Use TLS: Yes"
    echo "  • Port: 993"
    echo "  • Attachment Limit: 10 MB"
    echo "  • Enable Auto Reply: No"
    echo ""
    echo "═══ Email Domain ═══"
    echo ""
    echo "1. Press Ctrl+K, search: ${BOLD}Email Domain${NC}"
    echo "2. Click + New"
    echo "3. Fill in:"
    echo "  • Domain Name: byrne-accounts.org"
    echo "  • Email Server: mail.securenexus.net"
    echo "  • SMTP Port: 587"
    echo "  • Use TLS: Yes"
    echo "  • IMAP Folder: INBOX"
    echo ""
    echo "═══ Email Templates ═══"
    echo ""
    echo "Customize email templates:"
    echo ""
    echo "1. Press Ctrl+K, search: ${BOLD}Email Template${NC}"
    echo "2. Default templates:"
    echo "   • Sales Invoice"
    echo "   • Purchase Order"
    echo "   • Payment Receipt"
    echo ""
    echo "Create custom template:"
    echo "  • Click + New"
    echo "  • Name: Invoice Reminder"
    echo "  • Use HTML: Yes"
    echo "  • Subject: Outstanding Invoice {{ doc.name }}"
    echo "  • Body: (Use HTML editor)"
    echo ""
    echo "═══ Notification Setup ═══"
    echo ""
    echo "Configure automatic notifications:"
    echo ""
    echo "1. Press Ctrl+K, search: ${BOLD}Notification${NC}"
    echo "2. Click + New"
    echo ""
    echo "Example - New Sales Order notification:"
    echo "  • Document Type: Sales Order"
    echo "  • Send Alert On: New"
    echo "  • Recipients:"
    echo "    - Field: owner"
    echo "    - Email: sales@company.com"
    echo "  • Subject: New Order {{ doc.name }}"
    echo "  • Message: (custom message)"
    echo ""
    echo "═══ Testing Email ═══"
    echo ""
    echo "1. Go to any Sales Invoice"
    echo "2. Click 'Email' button"
    echo "3. Recipients: your email"
    echo "4. Click 'Send'"
    echo "5. Check inbox for delivery"
    echo ""

    read -p "Mark email integration as complete? [y/N]: " -r confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        mark_complete 'email'
        print_success "Email integration marked complete!"
    fi

    pause
}

# 9. Print Formats Guide
print_formats_guide() {
    print_header
    print_section "Print Formats & Templates"

    echo "Customize how documents print (invoices, receipts, etc.)."
    echo ""
    echo "═══ Print Settings ═══"
    echo ""
    echo "1. Press ${BOLD}Ctrl+K${NC}, search: ${BOLD}Print Settings${NC}"
    echo "2. Configure:"
    echo ""
    echo "${BOLD}General:${NC}"
    echo "  • Print with Company Letterhead: Yes"
    echo "  • Compact Item Print: No (shows full details)"
    echo "  • Send Print as PDF: Yes"
    echo "  • Always add 'Draft' for draft docs: Yes"
    echo "  • Allow Print for Draft: No"
    echo "  • Allow Page Break Inside Table: Yes"
    echo ""
    echo "${BOLD}PDF Settings:${NC}"
    echo "  • PDF Page Size: A4"
    echo "  • PDF Font Size: 9"
    echo "  • Print with CSS: Yes"
    echo ""
    echo "3. Save"
    echo ""
    echo "═══ Letterhead ═══"
    echo ""
    echo "Create company letterhead:"
    echo ""
    echo "1. Press Ctrl+K, search: ${BOLD}Letter Head${NC}"
    echo "2. Click + New"
    echo "3. Fill in:"
    echo "  • Letter Head Name: Company Letterhead"
    echo "  • Is Default: Yes"
    echo "  • Header: Upload image or HTML:"
    echo ""
    echo "    Example HTML:"
    echo '    <div style="text-align: center; padding: 20px;">'
    echo '      <img src="/files/logo.png" style="height: 60px;"><br>'
    echo '      <h2>Your Company Name</h2>'
    echo '      <p>Address Line 1 | City | Postcode</p>'
    echo '      <p>Tel: +44... | Email: info@company.com</p>'
    echo '    </div>'
    echo ""
    echo "  • Footer: (optional)"
    echo '    <div style="text-align: center; font-size: 9px;">'
    echo '      <p>Company Reg: 12345678 | VAT: GB123456789</p>'
    echo '    </div>'
    echo ""
    echo "4. Save"
    echo ""
    echo "═══ Print Format ═══"
    echo ""
    echo "Customize document layouts:"
    echo ""
    echo "1. Press Ctrl+K, search: ${BOLD}Print Format${NC}"
    echo "2. Click + New"
    echo "3. Fill in:"
    echo "  • Doc Type: Sales Invoice"
    echo "  • Name: Custom Invoice"
    echo "  • Default: Yes"
    echo "  • Margin (in mm):"
    echo "    Top: 15, Right: 15, Bottom: 15, Left: 15"
    echo ""
    echo "${BOLD}Print Format Builder:${NC}"
    echo "  4. Click 'Edit Format'"
    echo "  5. Drag & drop fields:"
    echo "     • Company logo"
    echo "     • Customer details"
    echo "     • Invoice items table"
    echo "     • Payment terms"
    echo "     • Bank details"
    echo "     • QR code (for payments)"
    echo "  6. Save"
    echo ""
    echo "═══ Custom Print Format (Jinja Template) ═══"
    echo ""
    echo "For advanced customization:"
    echo ""
    echo "1. Create new Print Format"
    echo "2. Check 'Custom Format'"
    echo "3. Check 'Raw Printing'"
    echo "4. HTML field opens - write custom HTML/Jinja:"
    echo ""
    echo "Example minimal invoice:"
    echo '{% raw %}'
    echo '<div class="invoice">'
    echo '  <h1>INVOICE</h1>'
    echo '  <p>Invoice No: {{ doc.name }}</p>'
    echo '  <p>Date: {{ doc.posting_date }}</p>'
    echo '  <p>Customer: {{ doc.customer_name }}</p>'
    echo '  '
    echo '  <table>'
    echo '    <thead><tr><th>Item</th><th>Qty</th><th>Rate</th><th>Amount</th></tr></thead>'
    echo '    <tbody>'
    echo '    {% for item in doc.items %}'
    echo '      <tr>'
    echo '        <td>{{ item.item_name }}</td>'
    echo '        <td>{{ item.qty }}</td>'
    echo '        <td>{{ item.rate }}</td>'
    echo '        <td>{{ item.amount }}</td>'
    echo '      </tr>'
    echo '    {% endfor %}'
    echo '    </tbody>'
    echo '  </table>'
    echo '  '
    echo '  <p>Total: {{ doc.grand_total }}</p>'
    echo '</div>'
    echo '{% endraw %}'
    echo ""
    echo "═══ Testing Print Formats ═══"
    echo ""
    echo "1. Open any Sales Invoice"
    echo "2. Click 'Print' dropdown"
    echo "3. Select your custom format"
    echo "4. Click 'Print Preview'"
    echo "5. Review and download PDF"
    echo ""

    read -p "Mark print formats as complete? [y/N]: " -r confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        mark_complete 'printing'
        print_success "Print formats marked complete!"
    fi

    pause
}

# 10. Branding Guide
branding_guide() {
    print_header
    print_section "Custom Branding & Themes"

    echo "Apply custom branding and visual identity."
    echo ""
    echo "═══ Quick Branding (Automated Script) ═══"
    echo ""
    echo "Run the automated branding script:"
    echo ""
    print_info "Command: ${BOLD}docker exec -it erpnext-backend bash /custom-branding/install-branding.sh${NC}"
    echo ""
    echo "This applies:"
    echo "  ✓ Custom CSS (blue/green color scheme)"
    echo "  ✓ Logo integration"
    echo "  ✓ Login page styling"
    echo "  ✓ Custom JavaScript enhancements"
    echo ""
    echo "═══ Manual Branding Setup ═══"
    echo ""
    echo "${BOLD}1. Website Settings${NC}"
    echo ""
    echo "Press Ctrl+K, search: ${BOLD}Website Settings${NC}"
    echo ""
    echo "  • Banner Image: Upload hero image"
    echo "  • Brand HTML: Company name/logo HTML"
    echo "  • Copyright: © 2025 Your Company"
    echo "  • Footer Address: Full address"
    echo "  • Hide Footer Signup: Yes (if not using web)"
    echo "  • Disable Signup: Yes (for private access)"
    echo ""
    echo "${BOLD}2. Website Theme${NC}"
    echo ""
    echo "Press Ctrl+K, search: ${BOLD}Website Theme${NC}"
    echo "Click + New"
    echo ""
    echo "  • Theme Name: Company Theme"
    echo "  • Apply To: (all pages or specific)"
    echo "  • Custom SCSS:"
    echo ""
    echo "    \$primary: #3b82f6;"
    echo "    \$secondary: #10b981;"
    echo "    \$body-bg: #ffffff;"
    echo "    \$font-family-base: 'Inter', sans-serif;"
    echo ""
    echo "${BOLD}3. Custom CSS${NC}"
    echo ""
    echo "In Website Settings, add to 'Custom CSS':"
    echo ""
    echo "  /* Main app colors */"
    echo "  :root {"
    echo "    --primary-color: #3b82f6;"
    echo "    --secondary-color: #10b981;"
    echo "  }"
    echo "  "
    echo "  /* Navbar branding */"
    echo "  .navbar {"
    echo "    background: white !important;"
    echo "    border-bottom: 3px solid var(--primary-color);"
    echo "  }"
    echo "  "
    echo "  /* Button styling */"
    echo "  .btn-primary {"
    echo "    background: var(--primary-color);"
    echo "  }"
    echo ""
    echo "${BOLD}4. Upload Logo${NC}"
    echo ""
    echo "1. Go to: Home > Website > Website Settings"
    echo "2. App Logo: Upload your logo"
    echo "3. Banner Image: Upload banner (1920x400px recommended)"
    echo "4. Favicon: Upload .ico file (32x32px)"
    echo ""
    echo "${BOLD}5. Desk Background${NC}"
    echo ""
    echo "Users can set personal backgrounds:"
    echo "1. User menu > Set Desktop Background"
    echo "2. Or: Home > Settings > Desktop > Desktop Settings"
    echo "   • Background Image: Upload company wallpaper"
    echo "   • Background Color: Or use solid color"
    echo ""
    echo "═══ Portal Branding ═══"
    echo ""
    echo "For customer portal:"
    echo ""
    echo "1. Press Ctrl+K, search: ${BOLD}Portal Settings${NC}"
    echo "2. Configure:"
    echo "   • Default Portal Role: Customer"
    echo "   • Custom Menu Items:"
    echo "     - Invoices"
    echo "     - Orders"
    echo "     - Tickets"
    echo "   • Hide Standard Menu: No"
    echo ""
    echo "═══ Testing Branding ═══"
    echo ""
    echo "1. Logout of ERPNext"
    echo "2. Clear browser cache (Ctrl+Shift+Del)"
    echo "3. Visit: $ERP_URL"
    echo "4. Check login page branding"
    echo "5. Login and check desk interface"
    echo ""

    read -p "Mark branding as complete? [y/N]: " -r confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        mark_complete 'branding'
        print_success "Branding marked complete!"
    fi

    pause
}

# Advanced Settings Menu
advanced_settings_menu() {
    while true; do
        print_header
        print_section "Advanced Settings Menu"

        echo "  A. $(get_completion_status 'tax-setup') Tax Rules & Templates"
        echo "  B. $(get_completion_status 'payment-gateway') Payment Gateway Integration"
        echo "  C. $(get_completion_status 'multi-currency') Multi-Currency Setup"
        echo "  D. $(get_completion_status 'subscription') Subscription Management"
        echo "  E. $(get_completion_status 'projects') Project Management"
        echo "  F. $(get_completion_status 'manufacturing') Manufacturing & BOM"
        echo "  G. $(get_completion_status 'quality') Quality Management"
        echo "  H. $(get_completion_status 'assets') Asset Management"
        echo "  I. $(get_completion_status 'maintenance') Maintenance Module"
        echo "  J. $(get_completion_status 'loan') Loan Management"
        echo "  K. $(get_completion_status 'website') Website & E-commerce"
        echo "  L. $(get_completion_status 'integrations') Third-party Integrations"
        echo ""
        echo "  M. Back to Main Menu"
        echo ""

        read -p "Select option [A-L, M]: " choice

        case $choice in
            [Aa]) tax_setup_guide ;;
            [Bb]) payment_gateway_guide ;;
            [Cc]) multi_currency_guide ;;
            [Dd]) subscription_guide ;;
            [Ee]) projects_guide ;;
            [Ff]) manufacturing_guide ;;
            [Gg]) quality_guide ;;
            [Hh]) assets_guide ;;
            [Ii]) maintenance_guide ;;
            [Jj]) loan_guide ;;
            [Kk]) website_ecommerce_guide ;;
            [Ll]) integrations_guide ;;
            [Mm]) return ;;
            *) print_error "Invalid option" ; sleep 1 ;;
        esac
    done
}

# Placeholder functions for remaining guides
advanced_accounting_guide() {
    print_header
    print_section "Advanced Accounting Settings"
    echo "Coming soon: Cost centers, budgeting, multi-company accounting"
    pause
}

hr_settings_guide() {
    print_header
    print_section "HR & Payroll Configuration"
    echo "Coming soon: Employee management, leave, attendance, payroll"
    pause
}

crm_settings_guide() {
    print_header
    print_section "CRM & Sales Pipeline"
    echo "Coming soon: Lead management, opportunities, campaigns"
    pause
}

reports_dashboards_guide() {
    print_header
    print_section "Reports & Dashboards"
    echo "Coming soon: Custom reports, dashboards, charts"
    pause
}

automation_guide() {
    print_header
    print_section "Workflow & Automation"
    echo "Coming soon: Workflow rules, auto-repeat, scheduled events"
    pause
}

tax_setup_guide() {
    print_header
    print_section "Tax Rules & Templates"
    echo "Coming soon: VAT setup, tax categories, withholding tax"
    pause
}

payment_gateway_guide() {
    print_header
    print_section "Payment Gateway Integration"
    echo "Coming soon: Stripe, PayPal, Razorpay integration"
    pause
}

multi_currency_guide() {
    print_header
    print_section "Multi-Currency Setup"
    echo "Coming soon: Exchange rates, multi-currency transactions"
    pause
}

subscription_guide() {
    print_header
    print_section "Subscription Management"
    echo "Coming soon: Recurring invoices, subscription plans"
    pause
}

projects_guide() {
    print_header
    print_section "Project Management"
    echo "Coming soon: Projects, tasks, timesheets"
    pause
}

manufacturing_guide() {
    print_header
    print_section "Manufacturing & BOM"
    echo "Coming soon: Bill of materials, work orders, production"
    pause
}

quality_guide() {
    print_header
    print_section "Quality Management"
    echo "Coming soon: Quality inspections, goals, procedures"
    pause
}

assets_guide() {
    print_header
    print_section "Asset Management"
    echo "Coming soon: Fixed assets, depreciation, maintenance"
    pause
}

maintenance_guide() {
    print_header
    print_section "Maintenance Module"
    echo "Coming soon: Preventive maintenance, schedules, repairs"
    pause
}

loan_guide() {
    print_header
    print_section "Loan Management"
    echo "Coming soon: Loan applications, repayment schedules"
    pause
}

website_ecommerce_guide() {
    print_header
    print_section "Website & E-commerce"
    echo "Coming soon: Shopping cart, product catalog, checkout"
    pause
}

integrations_guide() {
    print_header
    print_section "Third-party Integrations"
    echo "Coming soon: API setup, webhooks, external apps"
    pause
}

# 16. Testing & Verification
testing_verification() {
    print_header
    print_section "Testing & Verification"

    echo "Final system testing checklist."
    echo ""
    echo "═══ Basic Operations Test ═══"
    echo ""
    echo "☐ Create a test customer"
    echo "☐ Create test items/services"
    echo "☐ Create a quotation"
    echo "☐ Convert to sales order"
    echo "☐ Create delivery note"
    echo "☐ Create sales invoice"
    echo "☐ Record payment"
    echo "☐ Print invoice"
    echo "☐ Email invoice to test address"
    echo ""
    echo "═══ POS Test ═══"
    echo ""
    echo "☐ Access POS interface"
    echo "☐ Add items to cart"
    echo "☐ Apply discount"
    echo "☐ Process cash payment"
    echo "☐ Process card payment"
    echo "☐ Print receipt"
    echo "☐ Close POS shift"
    echo "☐ Verify cash reconciliation"
    echo ""
    echo "═══ Accounting Verification ═══"
    echo ""
    echo "☐ Check General Ledger"
    echo "☐ Verify Trial Balance"
    echo "☐ Run Profit & Loss report"
    echo "☐ Check Balance Sheet"
    echo "☐ Verify Accounts Receivable"
    echo "☐ Check Accounts Payable"
    echo "☐ Review Cash Flow"
    echo ""
    echo "═══ Inventory Check ═══"
    echo ""
    echo "☐ Stock Balance report"
    echo "☐ Stock Ledger verification"
    echo "☐ Create stock entry"
    echo "☐ Transfer between warehouses"
    echo "☐ Check stock levels"
    echo ""
    echo "═══ User Access Test ═══"
    echo ""
    echo "☐ Login as different user roles"
    echo "☐ Verify permissions work correctly"
    echo "☐ Test restricted access"
    echo "☐ Check user can't access forbidden areas"
    echo ""
    echo "═══ Reports Test ═══"
    echo ""
    echo "☐ Sales Register"
    echo "☐ Purchase Register"
    echo "☐ Item-wise Sales"
    echo "☐ Customer-wise Sales"
    echo "☐ Gross Profit report"
    echo ""

    read -p "Mark testing as complete? [y/N]: " -r confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        mark_complete 'testing'
        print_success "Testing marked complete!"
    fi

    pause
}

# System Information
show_system_info() {
    print_header
    print_section "System Information"

    echo "${BOLD}ERPNext Access:${NC}"
    echo "  URL: $ERP_URL"
    echo "  POS: https://pos.byrne-accounts.org"
    echo "  Username: Administrator"
    if [ -f "$ADMIN_PASSWORD_FILE" ]; then
        echo "  Password: $(cat $ADMIN_PASSWORD_FILE)"
    fi
    echo ""

    echo "${BOLD}Container Status:${NC}"
    docker compose ps | grep erpnext
    echo ""

    echo "${BOLD}Documentation:${NC}"
    echo "  • docs/ERPNEXT_COMPLETE_SETUP_GUIDE.md"
    echo "  • docs/ERPNEXT_QUICK_REFERENCE.md"
    echo "  • docs/ERPNEXT_SSO_SETUP.md"
    echo "  • docs/ERPNEXT_MAILCOW_INTEGRATION.md"
    echo ""

    echo "${BOLD}Useful Commands:${NC}"
    echo "  • Restart ERPNext: docker compose restart erpnext-backend"
    echo "  • View logs: docker compose logs -f erpnext-backend"
    echo "  • Access console: docker exec -it erpnext-backend bash"
    echo "  • Clear cache: bench --site $SITE clear-cache"
    echo ""

    pause
}

# Reset Progress
reset_progress() {
    print_header
    print_section "Reset Progress"

    print_warning "This will reset all completion tracking."
    read -p "Are you sure? [y/N]: " -r confirm

    if [[ $confirm =~ ^[Yy]$ ]]; then
        rm -f "$PROGRESS_FILE"
        touch "$PROGRESS_FILE"
        print_success "Progress reset complete!"
    else
        print_info "Cancelled"
    fi

    sleep 2
}

# Start the wizard
main() {
    # Check if running from correct directory
    if [ ! -f "compose.yml" ]; then
        print_error "Please run this script from the securenexus-fullstack directory"
        exit 1
    fi

    show_main_menu
}

# Run main function
main
