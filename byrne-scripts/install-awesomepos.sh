#!/bin/bash
#
# AwesomePOS Installation Script for ERPNext
#
# This script installs the AwesomePOS app into the ERPNext container
# AwesomePOS provides a modern, intuitive POS interface that syncs with ERPNext
#
# Usage: ./byrne-scripts/install-awesomepos.sh
#

set -e

echo "========================================="
echo "AwesomePOS Installation for ERPNext"
echo "========================================="
echo ""

# Check if erpnext-backend container is running
if ! docker ps | grep -q erpnext-backend; then
    echo "ERROR: erpnext-backend container is not running"
    echo "Please start the Byrne Accounting stack first:"
    echo "  make up-byrne"
    exit 1
fi

echo "Step 1: Installing AwesomePOS app..."
docker exec -it erpnext-backend bash -c "
    cd /home/frappe/frappe-bench &&
    bench get-app https://github.com/ucraft-com/POS-Awesome &&
    bench --site erp.byrne-accounts.org install-app posawesome
"

if [ $? -eq 0 ]; then
    echo "✓ AwesomePOS installed successfully"
else
    echo "✗ Failed to install AwesomePOS"
    exit 1
fi

echo ""
echo "Step 2: Configuring POS profiles..."
docker exec -it erpnext-backend bash -c "
    cd /home/frappe/frappe-bench &&
    bench --site erp.byrne-accounts.org console <<'EOF'
# Create default POS profile
from frappe import get_doc

if not frappe.db.exists('POS Profile', 'Default POS Profile'):
    pos_profile = get_doc({
        'doctype': 'POS Profile',
        'name': 'Default POS Profile',
        'enabled': 1,
        'use_pos_in_offline_mode': 0,
        'selling_price_list': 'Standard Selling',
        'currency': 'USD',
        'write_off_account': 'Write Off - Company',
        'write_off_cost_center': 'Main - Company',
        'payments': [
            {
                'mode_of_payment': 'Cash',
                'default': 1
            },
            {
                'mode_of_payment': 'Credit Card'
            }
        ]
    })
    pos_profile.insert()
    frappe.db.commit()
    print('POS Profile created successfully')
else:
    print('POS Profile already exists')
EOF
"

echo ""
echo "Step 3: Setting up POS permissions..."
docker exec -it erpnext-backend bash -c "
    cd /home/frappe/frappe-bench &&
    bench --site erp.byrne-accounts.org add-to-hosts &&
    bench --site erp.byrne-accounts.org migrate &&
    bench --site erp.byrne-accounts.org build --apps posawesome
"

if [ $? -eq 0 ]; then
    echo "✓ POS configuration completed"
else
    echo "✗ Failed to configure POS"
    exit 1
fi

echo ""
echo "Step 4: Restarting ERPNext services..."
docker compose restart erpnext-backend erpnext-worker

echo ""
echo "========================================="
echo "AwesomePOS Installation Complete!"
echo "========================================="
echo ""
echo "Access Points:"
echo "  • ERP System: https://erp.byrne-accounts.org"
echo "  • POS System: https://pos.byrne-accounts.org"
echo ""
echo "Default Credentials:"
echo "  • Username: Administrator"
echo "  • Password: (stored in secrets/erpnext_admin_password.txt)"
echo ""
echo "Next Steps:"
echo "  1. Log into ERPNext at https://erp.byrne-accounts.org"
echo "  2. Configure your POS Profile under: Retail > POS Profile"
echo "  3. Set up items, pricing, and payment methods"
echo "  4. Access AwesomePOS at https://pos.byrne-accounts.org"
echo ""
echo "Note: Both ERP and POS are protected by Authentik SSO"
echo "      You must configure Authentik integration first"
echo ""
