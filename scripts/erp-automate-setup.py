#!/usr/bin/env python3
"""
ERPNext Automated Setup Script
Completes the initial setup wizard and basic configuration
"""

import frappe
import sys
import json

def setup_erpnext(site, company_name, company_abbr):
    """
    Automate ERPNext initial setup
    """
    frappe.init(site=site)
    frappe.connect()

    try:
        # Check if setup is already complete
        if frappe.db.get_single_value('System Settings', 'setup_complete'):
            print(f"Setup already complete for {site}")
            return True

        # Complete setup wizard
        setup_data = {
            'language': 'en',
            'country': 'United Kingdom',
            'timezone': 'Europe/London',
            'currency': 'GBP',
            'company_name': company_name,
            'company_abbr': company_abbr,
            'bank_account': f'{company_name} Bank Account',
            'chart_of_accounts': 'United Kingdom',
            'fy_start_date': frappe.utils.get_first_day(frappe.utils.nowdate()).strftime('%Y-%m-%d'),
            'fy_end_date': frappe.utils.get_last_day(frappe.utils.add_years(frappe.utils.nowdate(), 0)).strftime('%Y-%m-%d'),
            'domains': ['Retail', 'Services']
        }

        # Execute setup
        from frappe.utils.install import complete_setup_wizard
        complete_setup_wizard(setup_data)

        frappe.db.commit()
        print(f"✓ Setup wizard completed for {company_name}")

        # Create main warehouse
        if not frappe.db.exists('Warehouse', f'Main Store - {company_abbr}'):
            warehouse = frappe.get_doc({
                'doctype': 'Warehouse',
                'warehouse_name': 'Main Store',
                'company': company_name,
                'is_group': 0
            })
            warehouse.insert()
            frappe.db.commit()
            print(f"✓ Created warehouse: Main Store - {company_abbr}")

        # Create POS profile
        if not frappe.db.exists('POS Profile', f'Main POS - {company_abbr}'):
            pos_profile = frappe.get_doc({
                'doctype': 'POS Profile',
                'name': f'Main POS - {company_abbr}',
                'company': company_name,
                'warehouse': f'Main Store - {company_abbr}',
                'currency': 'GBP',
                'selling_price_list': 'Standard Selling',
                'write_off_account': f'Write Off - {company_abbr}',
                'write_off_cost_center': f'Main - {company_abbr}',
                'payments': [
                    {
                        'mode_of_payment': 'Cash',
                        'default': 1
                    },
                    {
                        'mode_of_payment': 'Card',
                        'default': 0
                    }
                ]
            })
            pos_profile.insert()
            frappe.db.commit()
            print(f"✓ Created POS Profile: Main POS - {company_abbr}")

        # Create default customer for walk-ins
        if not frappe.db.exists('Customer', 'Walk-In Customer'):
            customer = frappe.get_doc({
                'doctype': 'Customer',
                'customer_name': 'Walk-In Customer',
                'customer_type': 'Individual',
                'customer_group': 'Individual',
                'territory': 'United Kingdom'
            })
            customer.insert()
            frappe.db.commit()
            print("✓ Created Walk-In Customer")

        print("\n✓ ERPNext automated setup complete!")
        return True

    except Exception as e:
        print(f"Error during setup: {str(e)}")
        frappe.db.rollback()
        return False
    finally:
        frappe.destroy()

if __name__ == '__main__':
    if len(sys.argv) < 4:
        print("Usage: bench --site SITE run-script erp-automate-setup.py COMPANY_NAME COMPANY_ABBR")
        sys.exit(1)

    site = sys.argv[1]
    company_name = sys.argv[2]
    company_abbr = sys.argv[3]

    success = setup_erpnext(site, company_name, company_abbr)
    sys.exit(0 if success else 1)
