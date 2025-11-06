# ERPNext Interactive Setup Wizard

A comprehensive guided setup wizard for configuring ERPNext with all basic and advanced settings.

## Quick Start

```bash
cd /home/tristian/securenexus-fullstack
./scripts/erp-setup-wizard.sh
```

## What It Covers

The wizard provides step-by-step guidance for:

### Basic Setup (Essential)

1. **Initial ERPNext Setup Wizard**
   - Language & region configuration
   - Company information
   - Fiscal year setup
   - Module selection
   - First-time initialization

2. **Company Settings & Configuration**
   - Detailed company profile
   - Contact information
   - Address management
   - Tax settings (VAT, Companies House)
   - Default accounting accounts
   - Cost centers
   - Company letterhead

3. **Chart of Accounts Setup**
   - Review UK chart of accounts structure
   - Add custom accounts
   - Configure account hierarchy
   - Tax account mapping

4. **Point of Sale (POS) Configuration**
   - Warehouse creation
   - POS profile setup
   - Payment methods (Cash, Card, Bank Transfer)
   - POS Awesome settings
   - Print format configuration
   - Walk-in customer setup

5. **Inventory & Stock Management**
   - Stock settings configuration
   - Warehouse management
   - Item groups organization
   - Stock reconciliation
   - Reorder levels
   - Batch/serial number tracking

6. **Products/Services & Price Lists**
   - Creating items (products/services)
   - Standard selling/buying rates
   - Tax templates
   - Price lists (Retail, Wholesale)
   - Item variants (size, color)
   - Bulk import via CSV/Excel

7. **User Management & Permissions**
   - Creating users
   - Role assignments (POS Cashier, Accountant, Manager, etc.)
   - User permissions (warehouse, company restrictions)
   - Role permission customization
   - Password policies
   - Two-factor authentication

8. **Email Integration Setup**
   - Mailcow SMTP configuration
   - Email account setup
   - Email domain configuration
   - Email templates customization
   - Notification rules
   - Automated alerts

9. **Print Formats & Templates**
   - Print settings configuration
   - Letterhead creation
   - Custom invoice formats
   - Print format builder
   - Custom HTML/Jinja templates
   - PDF customization

10. **Custom Branding & Themes**
    - Automated branding script
    - Website settings
    - Custom CSS/SCSS
    - Logo and favicon upload
    - Desktop backgrounds
    - Portal branding

### Advanced Settings

11. **Advanced Accounting Settings**
    - Cost centers
    - Budgeting
    - Multi-company accounting
    - Depreciation
    - Deferred revenue/expenses

12. **HR & Payroll Configuration**
    - Employee management
    - Leave types
    - Attendance tracking
    - Salary structure
    - Payroll processing
    - Loan management

13. **CRM & Sales Pipeline**
    - Lead management
    - Opportunity tracking
    - Sales pipeline stages
    - Campaign management
    - Customer journey

14. **Reports & Dashboards**
    - Custom report creation
    - Dashboard widgets
    - Chart creation
    - Scheduled reports
    - Report permissions

15. **Workflow & Automation**
    - Workflow rules
    - Auto-repeat transactions
    - Email alerts
    - Assignment rules
    - Scheduled events

16. **Testing & Verification**
    - Complete system testing checklist
    - Transaction flow verification
    - Accounting validation
    - User access testing
    - Report generation

### Additional Advanced Modules

- **Tax Rules & Templates** - VAT setup, tax categories, withholding tax
- **Payment Gateway Integration** - Stripe, PayPal, Razorpay
- **Multi-Currency Setup** - Exchange rates, multi-currency transactions
- **Subscription Management** - Recurring invoices, subscription plans
- **Project Management** - Projects, tasks, timesheets, billing
- **Manufacturing & BOM** - Bill of materials, work orders, production planning
- **Quality Management** - Quality inspections, goals, procedures
- **Asset Management** - Fixed assets, depreciation, maintenance schedules
- **Maintenance Module** - Preventive maintenance, repair tracking
- **Website & E-commerce** - Shopping cart, product catalog, online checkout
- **Third-party Integrations** - API setup, webhooks, external apps

## Features

### Interactive Menu System
- ✅ Visual progress tracking
- ✅ Color-coded status indicators
- ✅ Section completion markers
- ✅ Non-linear navigation (jump to any section)
- ✅ Progress persistence (resume anytime)

### Step-by-Step Guidance
Each section provides:
- Detailed instructions with screenshots references
- Recommended settings for UK businesses
- Best practices and tips
- Field-by-field configuration guidance
- Common pitfalls and warnings

### Progress Tracking
- Automatically saves completion status
- Visual indicators: `[DONE]` / `[TODO]`
- Resume from where you left off
- Reset progress option available

## Usage

### First Time Setup

```bash
# Start the wizard
./scripts/erp-setup-wizard.sh

# Follow sections in order 1-10 for basic setup
# Then proceed to advanced settings as needed
```

### Navigation

- **Numbers 1-16**: Main setup sections
- **A**: Advanced Settings submenu
- **S**: Show system information
- **R**: Reset progress tracking
- **Q**: Quit wizard

### Marking Sections Complete

At the end of each section, you'll be prompted:
```
Mark [section name] as complete? [y/N]:
```

Answer `y` to track completion (visual indicator changes to `[DONE]`)

### System Information Screen

Press `S` from main menu to view:
- ERPNext access URLs
- Admin credentials
- Container status
- Documentation links
- Useful commands

## Prerequisites

Before running the wizard:

1. **ERPNext must be running**
   ```bash
   docker compose ps | grep erpnext
   # All containers should show "Up" status
   ```

2. **Admin password available**
   ```bash
   cat secrets/erpnext_admin_password.txt
   ```

3. **Browser access to ERPNext**
   - Main: https://erp.byrne-accounts.org
   - POS: https://pos.byrne-accounts.org

## Recommended Workflow

### Phase 1: Foundation (Essential)
Complete sections 1-7 first:
1. Initial wizard
2. Company settings
3. Chart of accounts
4. POS profile
5. Inventory
6. Products/services
7. Users

### Phase 2: Operations (Important)
Then configure:
8. Email integration
9. Print formats
10. Branding

### Phase 3: Advanced Features (As Needed)
Finally, set up advanced modules based on business needs:
- Accounting (budgeting, cost centers)
- HR (if managing employees)
- CRM (for sales pipeline)
- Projects (for project-based billing)
- Manufacturing (if applicable)

## Tips for Success

1. **Work in Order**: Follow sections sequentially for first-time setup
2. **Test Frequently**: Use section 16 to verify configurations
3. **Document Decisions**: Note custom account names, warehouses, etc.
4. **Backup Before Changes**: Run backup before major configuration
5. **One Section at a Time**: Complete and test each section before moving on

## Common Commands

### While Following the Wizard

```bash
# View ERPNext logs
docker compose logs -f erpnext-backend

# Restart ERPNext
docker compose restart erpnext-backend

# Access ERPNext console
docker exec -it erpnext-backend bash

# Clear cache (if changes don't appear)
docker exec -it erpnext-backend bench --site erp.byrne-accounts.org clear-cache

# Apply branding
docker exec -it erpnext-backend bash /custom-branding/install-branding.sh
```

### Wizard Commands

```bash
# Start wizard
./scripts/erp-setup-wizard.sh

# View wizard progress file
cat /tmp/erp-wizard-progress.txt

# Reset all progress
rm /tmp/erp-wizard-progress.txt
```

## Keyboard Shortcuts (in ERPNext)

The wizard frequently references these shortcuts:

- `Ctrl+K` (or `Cmd+K` on Mac) - **Awesome Bar** (search anything)
- `Ctrl+G` - Go to next field
- `Ctrl+S` - Save document
- `Ctrl+Shift+S` - Save and submit
- `Ctrl+B` - Toggle sidebar

## Support & Documentation

### Related Guides
- `docs/ERPNEXT_COMPLETE_SETUP_GUIDE.md` - Detailed setup guide
- `docs/ERPNEXT_QUICK_REFERENCE.md` - Quick command reference
- `docs/ERPNEXT_SSO_SETUP.md` - SSO integration
- `docs/ERPNEXT_MAILCOW_INTEGRATION.md` - Email setup

### Official Resources
- ERPNext Documentation: https://docs.erpnext.com
- Frappe Forum: https://discuss.erpnext.com
- POS Awesome: https://github.com/yrestom/POS-Awesome

## Troubleshooting

### Wizard won't start
```bash
# Ensure you're in the right directory
cd /home/tristian/securenexus-fullstack

# Check script is executable
chmod +x scripts/erp-setup-wizard.sh
```

### ERPNext not accessible
```bash
# Check containers running
docker compose ps | grep erpnext

# Restart if needed
docker compose restart erpnext-backend erpnext-socketio
```

### Changes not appearing
```bash
# Clear ERPNext cache
docker exec -it erpnext-backend bench --site erp.byrne-accounts.org clear-cache

# Hard refresh browser (Ctrl+Shift+R)
```

### Can't remember admin password
```bash
# View password
cat /home/tristian/securenexus-fullstack/secrets/erpnext_admin_password.txt
```

## Advanced Usage

### Custom Progress Tracking

The wizard stores progress in `/tmp/erp-wizard-progress.txt`

You can manually edit this file to mark sections complete:
```bash
echo "initial-wizard" >> /tmp/erp-wizard-progress.txt
echo "company-settings" >> /tmp/erp-wizard-progress.txt
```

### Running Specific Sections

The wizard is non-linear - you can jump to any section directly from the main menu.

### Integration with Other Scripts

The wizard complements these existing scripts:
- `scripts/install-erp-branding.sh` - Automated branding (called from wizard)
- `scripts/backup-all.sh` - Backup before configuration
- `scripts/generate-secrets.sh` - Initial secret generation

## What's Next?

After completing the wizard:

1. **Import Real Data**
   - Import customers (Data Import tool)
   - Import items/products
   - Import opening balances

2. **Configure Advanced Features**
   - Set up workflows
   - Create custom fields
   - Configure automation rules

3. **Train Users**
   - Conduct user training sessions
   - Share documentation
   - Set up user-specific shortcuts

4. **Go Live**
   - Final system testing (section 16)
   - Backup configuration
   - Switch to production mode

## Feedback & Improvements

The wizard is continuously evolving. Suggested improvements:
- Additional sections for specific industries
- Video walkthrough references
- Integration testing automation
- Configuration export/import

---

**Version**: 1.0
**Last Updated**: October 31, 2025
**Maintainer**: SecureNexus Infrastructure Team
