# Complete Client Provisioning Guide

**Version**: 2.0 (with Integrated Wizard)
**Last Updated**: November 1, 2025

---

## 🎯 Overview

This guide covers the **complete end-to-end process** for provisioning a new client with:

- ✅ ERPNext multi-tenant site
- ✅ POS Awesome point of sale system
- ✅ Professional email with aliases
- ✅ SSL certificates (automatic)
- ✅ Portal integration
- ✅ **Guided setup wizard** (16 comprehensive sections)

**Total Time**: 30-60 minutes (depending on configuration depth)

---

## 📋 Prerequisites

### 1. System Requirements

```bash
# Check all services are running
docker compose ps

# Required services:
# - erpnext-backend (Up, healthy)
# - erpnext-db (Up, healthy)
# - traefik (Up)
# - Mailcow (running separately in mail/mailcow/)
```

### 2. Required Files

```bash
# Mailcow API key (for email automation)
cat secrets/mailcow_api_key.txt

# Should contain API key in format: XXXXX-XXXXX-XXXXX-XXXXX-XXXXX
```

**Don't have Mailcow API key?** See `docs/MAILCOW_API_SETUP.md` or the script will guide you through manual email setup.

### 3. DNS Configuration

Ensure wildcard DNS is configured:
```bash
# Test DNS resolution
dig +short newclient.byrne-accounts.org @8.8.8.8

# Should return your server IP
```

---

## 🚀 Quick Start

### One-Command Provisioning

```bash
cd /home/tristian/securenexus-fullstack

./scripts/provision-client-complete.sh \
  --name "ACME Corporation Ltd" \
  --subdomain "acme"
```

**Optional Parameters:**
```bash
# Custom email domain
./scripts/provision-client-complete.sh \
  --name "ACME Corp" \
  --subdomain "acme" \
  --domain "acmecorp.com"

# Different subscription plan
./scripts/provision-client-complete.sh \
  --name "Startup Inc" \
  --subdomain "startup" \
  --plan "starter"
```

---

## 📖 Complete Workflow

### Step 1: Infrastructure Provisioning

**Script Actions (Automated)**:

1. ✅ **Creates ERPNext site**: `subdomain.byrne-accounts.org`
   - MariaDB database created
   - ERPNext app installed
   - POS Awesome app installed

2. ✅ **Creates email system**:
   - Main mailbox: `subdomain@domain.com` (10GB quota)
   - 5 aliases forwarding to main inbox:
     - `support@domain.com`
     - `info@domain.com`
     - `financial@domain.com`
     - `sales@domain.com`
     - `accounts@domain.com`

3. ✅ **Generates secure credentials**:
   - ERP admin password (20 chars)
   - Email password (20 chars)
   - Saved to `client-credentials/subdomain.byrne-accounts.org.txt`

**Time**: ~3-5 minutes

---

### Step 2: Initial ERPNext Wizard (Browser)

**Script Action**: Pauses and prompts you to complete initial setup

**What to do**:

1. **Open browser**: `https://subdomain.byrne-accounts.org`

2. **Login**:
   - Username: `Administrator`
   - Password: *(shown in terminal)*

3. **Complete ERPNext Setup Wizard** (5 screens):

   **Screen 1 - Language & Region**:
   - Language: `English`
   - Country: `United Kingdom`
   - Timezone: `Europe/London`
   - Currency: `GBP (£)`

   **Screen 2 - Company Details**:
   - Company Name: `ACME Corporation Ltd` *(use client name)*
   - Company Abbreviation: `ACME` *(auto-suggested)*
   - Bank Name: `ACME Bank` *(or actual bank)*

   **Screen 3 - Chart of Accounts**:
   - Select: `United Kingdom`
   - Click: `Complete Setup`

   **Screen 4 - Fiscal Year** (auto-filled):
   - Start: `2025-01-01`
   - End: `2025-12-31`
   - Click: `Next`

   **Screen 5 - What does your company do?**:
   - Select relevant domains: `Retail`, `Services` *(as applicable)*
   - Click: `Complete Setup`

4. **Wait for setup** to complete (~30 seconds)

5. **Return to terminal** and press Enter

**Time**: 2-3 minutes

---

### Step 3: Email System Configuration

**Script Actions (Automated)**:

- ✅ Mailbox created in Mailcow
- ✅ All aliases configured
- ✅ Email ready to use

**Verification**:
```bash
# Test login to webmail
# URL: https://mail.securenexus.net
# Email: subdomain@byrne-accounts.org
# Password: (shown in terminal)
```

**Time**: 1 minute

---

### Step 4: Traefik Routing

**Script Action**: Shows Traefik labels to add

**What to do**:

1. Script will display labels like:
   ```yaml
   # Client site: acme.byrne-accounts.org
   - traefik.http.routers.erp-acme.rule=Host(`acme.byrne-accounts.org`)
   - traefik.http.routers.erp-acme.entrypoints=websecure
   ...
   ```

2. **Copy these labels** to `compose.yml` in the `erpnext-backend` service

3. **Press Enter** in terminal

4. Script will restart ERPNext backend

**Time**: 1-2 minutes

---

### Step 5: Portal Integration

**Script Action**: Shows portal HTML to add

**What to do**:

1. Edit: `byrne-website/portal.html`

2. Find the `<select id="clientSelect">` section

3. Add this line:
   ```html
   <option value="acme.byrne-accounts.org">ACME Corporation Ltd</option>
   ```

4. Rebuild portal:
   ```bash
   docker compose build byrne-website
   docker compose up -d byrne-website
   ```

**Time**: 1 minute

---

### Step 6: Interactive Configuration Wizard

**Script Action**: Automatically launches the interactive wizard

**What you'll see**:

```
╔══════════════════════════════════════════════════════════╗
║        ERPNext Complete Setup Wizard                     ║
║        Professional Configuration Assistant              ║
╚══════════════════════════════════════════════════════════╝

Setup Progress:

  1. [TODO] Initial ERPNext Setup Wizard
  2. [TODO] Company Settings & Configuration
  3. [TODO] Chart of Accounts Setup
  4. [TODO] Point of Sale (POS) Configuration
  5. [TODO] Inventory & Stock Management
  6. [TODO] Products/Services & Price Lists
  7. [TODO] User Management & Permissions
  8. [TODO] Email Integration Setup
  9. [TODO] Print Formats & Templates
 10. [TODO] Custom Branding & Themes
 11. [TODO] Advanced Accounting Settings
 12. [TODO] HR & Payroll Configuration
 13. [TODO] CRM & Sales Pipeline
 14. [TODO] Reports & Dashboards
 15. [TODO] Workflow & Automation
 16. [TODO] Testing & Verification

  S. Show System Information
  Q. Quit
```

---

## 🧙 Wizard Sections Guide

### Essential Sections (1-10)

Complete these for a **fully functional system**:

#### 1. Initial ERPNext Setup Wizard
- ✅ Language and region
- ✅ Company information
- ✅ Fiscal year setup
- ✅ Module selection

**Status**: Already completed in Step 2!

#### 2. Company Settings & Configuration
**What it covers**:
- Detailed company profile
- Contact information
- Address management
- Tax settings (VAT number, Companies House)
- Default accounting accounts
- Cost centers
- Company letterhead

**Access via wizard**:
- Press `2` → Follow instructions
- Browser: Search `Company` (Ctrl+K)

**Time**: 5-10 minutes

#### 3. Chart of Accounts Setup
**What it covers**:
- Review UK chart of accounts structure
- Add custom accounts if needed
- Configure account hierarchy
- Tax account mapping

**Access**: Press `3` → Review accounts in browser

**Time**: 5 minutes (review), 15+ minutes (customization)

#### 4. Point of Sale (POS) Configuration
**What it covers**:
- Warehouse creation (if not exists)
- POS profile setup
- Payment methods (Cash, Card, Bank Transfer)
- POS Awesome settings
- Print format configuration
- Walk-in customer setup

**Critical for**: Retail businesses, POS usage

**Time**: 10-15 minutes

#### 5. Inventory & Stock Management
**What it covers**:
- Stock settings configuration
- Warehouse management
- Item groups organization
- Stock reconciliation
- Reorder levels
- Batch/serial number tracking

**Time**: 10-20 minutes

#### 6. Products/Services & Price Lists
**What it covers**:
- Creating items (products/services)
- Standard selling/buying rates
- Tax templates
- Price lists (Retail, Wholesale)
- Item variants (size, color)
- Bulk import via CSV/Excel

**Time**: 15-30 minutes (depends on product count)

#### 7. User Management & Permissions
**What it covers**:
- Creating users (POS Cashier, Accountant, Manager)
- Role assignments
- User permissions (warehouse, company restrictions)
- Password policies
- Two-factor authentication (optional)

**Time**: 10-15 minutes

#### 8. Email Integration Setup
**What it covers**:
- Mailcow SMTP configuration
- Email account setup
- Email domain configuration
- Email templates customization
- Notification rules
- Automated alerts

**Settings**:
```
SMTP Server: mail.securenexus.net
SMTP Port: 587 (STARTTLS)
Username: subdomain@byrne-accounts.org
Password: (from credentials file)
```

**Time**: 10-15 minutes

#### 9. Print Formats & Templates
**What it covers**:
- Print settings configuration
- Letterhead creation
- Custom invoice formats
- Print format builder
- PDF customization

**Time**: 10-20 minutes

#### 10. Custom Branding & Themes
**What it covers**:
- Website settings
- Custom CSS/SCSS
- Logo and favicon upload
- Desktop backgrounds
- Portal branding

**Automated script available**:
```bash
# Run branding script (from wizard option)
docker exec erpnext-backend bash /custom-branding/install-branding.sh
```

**Time**: 5-10 minutes

---

### Advanced Sections (11-16)

Configure these **as needed** for your business:

#### 11. Advanced Accounting Settings
- Cost centers
- Budgeting
- Multi-company accounting
- Depreciation
- Deferred revenue/expenses

**Time**: 15-30 minutes

#### 12. HR & Payroll Configuration
- Employee management
- Leave types
- Attendance tracking
- Salary structure
- Payroll processing

**Time**: 20-40 minutes

#### 13. CRM & Sales Pipeline
- Lead management
- Opportunity tracking
- Sales pipeline stages
- Campaign management
- Customer journey

**Time**: 15-25 minutes

#### 14. Reports & Dashboards
- Custom report creation
- Dashboard widgets
- Chart creation
- Scheduled reports

**Time**: 10-20 minutes

#### 15. Workflow & Automation
- Workflow rules
- Auto-repeat transactions
- Email alerts
- Assignment rules

**Time**: 15-30 minutes

#### 16. Testing & Verification
- Complete system testing checklist
- Transaction flow verification
- Accounting validation
- User access testing

**Time**: 20-30 minutes

---

## 🎓 Wizard Tips

### Navigation

- **Jump to any section**: Enter section number (1-16)
- **Non-linear**: Don't have to go in order
- **Mark complete**: Answer 'y' when prompted after each section
- **Resume later**: Progress is saved, just quit (Q) and restart
- **System info**: Press 'S' to view URLs, credentials, commands

### Progress Tracking

The wizard tracks completion per site:
```bash
# View progress
cat /tmp/erp-wizard-progress-acme_byrne_accounts_org.txt

# Reset progress
rm /tmp/erp-wizard-progress-acme_byrne_accounts_org.txt
```

### Recommended Workflow

**Phase 1 - Foundation** (Complete first):
- Sections 1-7 (Setup through User Management)
- **Time**: ~1 hour
- **Result**: Functional ERP system

**Phase 2 - Polish** (Complete next):
- Sections 8-10 (Email, Printing, Branding)
- **Time**: 30-45 minutes
- **Result**: Professional, branded system

**Phase 3 - Advanced** (As needed):
- Sections 11-16 (based on business needs)
- **Time**: Variable
- **Result**: Full-featured enterprise system

---

## 📁 Generated Files & Credentials

### Credentials File

**Location**: `client-credentials/subdomain.byrne-accounts.org.txt`

**Contents**:
```
═══════════════════════════════════════════════════════════
  ACME Corporation Ltd - Complete Access Credentials
═══════════════════════════════════════════════════════════

PORTAL ACCESS:
  URL: https://byrne-accounts.org/portal.html
  Select: "ACME Corporation Ltd" from dropdown

ERP SYSTEM:
  URL: https://acme.byrne-accounts.org
  Username: Administrator
  Password: xK8dP2mN9qR5vL3w

POS SYSTEM:
  URL: https://acme.byrne-accounts.org/pos
  Username: Administrator
  Password: xK8dP2mN9qR5vL3w

EMAIL SYSTEM:
  Webmail: https://mail.securenexus.net
  Main Email: acme@byrne-accounts.org
  Password: yT7fG4hJ2kS6nP9x

  Available Addresses (all go to acme@byrne-accounts.org):
  • acme@byrne-accounts.org (main inbox)
  • support@byrne-accounts.org
  • info@byrne-accounts.org
  • financial@byrne-accounts.org
  • sales@byrne-accounts.org
  • accounts@byrne-accounts.org
```

**Security**: File is automatically set to `600` permissions (owner read/write only)

### Database

**Name**: `_acme_byrne_accounts_org`

**View**:
```bash
docker exec erpnext-db mysql -u root -p$(cat secrets/erpnext_db_password.txt) -e "SHOW DATABASES LIKE '%acme%';"
```

### Site Files

**Location**: Docker volume `erpnext-sites-data:/sites/acme.byrne-accounts.org/`

**Backup**:
```bash
docker exec erpnext-backend bench --site acme.byrne-accounts.org backup --with-files
```

---

## 🧪 Testing & Verification

### Quick Smoke Test

```bash
# 1. Test ERP access
curl -I https://acme.byrne-accounts.org
# Should return: HTTP/2 200

# 2. Test email login
# Browser: https://mail.securenexus.net
# Login with: acme@byrne-accounts.org

# 3. Test POS access
# Browser: https://acme.byrne-accounts.org/pos
# Should load POS Awesome interface

# 4. Test portal
# Browser: https://byrne-accounts.org/portal.html
# Select: "ACME Corporation Ltd"
# All 3 service cards should appear
```

### Comprehensive Testing

Use **Wizard Section 16** (Testing & Verification):
```bash
./scripts/erp-setup-wizard.sh acme.byrne-accounts.org
# Press: 16
```

Covers:
- ✅ Transaction flow testing
- ✅ Accounting validation
- ✅ User access verification
- ✅ Report generation
- ✅ Email notifications
- ✅ Print format testing

---

## 🔧 Troubleshooting

### Issue: Site creation fails

**Symptom**: Script exits with database error

**Solution**:
```bash
# Check database is running
docker compose ps erpnext-db

# Check database password
cat secrets/erpnext_db_password.txt

# Check database connectivity
docker exec erpnext-backend bench --site erp.byrne-accounts.org list-apps
```

### Issue: Email creation fails

**Symptom**: "Mailbox may already exist or API error"

**Solutions**:

1. **Check API key**:
   ```bash
   cat secrets/mailcow_api_key.txt
   # Should be format: XXXXX-XXXXX-XXXXX-XXXXX-XXXXX
   ```

2. **Test API key manually**:
   ```bash
   API_KEY=$(cat secrets/mailcow_api_key.txt)
   curl -H "X-API-Key: ${API_KEY}" https://mail.securenexus.net/api/v1/get/mailbox/all
   ```

3. **Create manually** (script will show instructions)

### Issue: SSL certificate not issued

**Symptom**: Browser shows certificate error after 10+ minutes

**Check**:
```bash
# View Traefik logs
docker compose logs traefik | grep acme.byrne-accounts.org

# Check DNS resolution
dig +short acme.byrne-accounts.org @8.8.8.8
```

**Solution**:
- DNS must resolve to server IP
- Port 80/443 must be open
- Wait 5-10 minutes for Let's Encrypt

### Issue: Wizard doesn't launch

**Symptom**: "command not found" or permission denied

**Solution**:
```bash
# Make executable
chmod +x scripts/erp-setup-wizard.sh

# Run from correct directory
cd /home/tristian/securenexus-fullstack
./scripts/erp-setup-wizard.sh acme.byrne-accounts.org
```

### Issue: ERPNext shows "Setup wizard not complete"

**Symptom**: After Step 2, ERPNext still shows wizard

**Solution**:
- Complete ALL 5 screens in the browser wizard
- Click "Complete Setup" on final screen
- Wait for processing (green checkmarks)
- Refresh browser if stuck

### Issue: POS not accessible

**Symptom**: `/pos` route shows 404

**Possible causes**:
1. POS Awesome not installed
2. POS profile not created
3. User doesn't have POS access

**Solution**:
```bash
# Check POS Awesome installed
docker exec erpnext-backend bench --site acme.byrne-accounts.org list-apps
# Should show: posawesome

# If not installed:
docker exec erpnext-backend bench --site acme.byrne-accounts.org install-app posawesome

# Complete Section 4 of wizard to create POS profile
```

---

## 📚 Related Documentation

- **Main Guide**: `docs/PROOF_OF_CONCEPT_COMPLETE.md` - System architecture
- **Wizard Reference**: `docs/ERPNEXT_WIZARD_GUIDE.md` - Detailed wizard instructions
- **Email Setup**: `docs/MAILCOW_API_SETUP.md` - Mailcow API configuration
- **Quick Reference**: `docs/ERPNEXT_QUICK_REFERENCE.md` - Common commands

---

## 🎯 Success Checklist

After provisioning, you should have:

- ✅ ERPNext site accessible at `https://subdomain.byrne-accounts.org`
- ✅ POS system accessible at `https://subdomain.byrne-accounts.org/pos`
- ✅ Email working (can login to webmail)
- ✅ All 5 aliases forwarding to main inbox
- ✅ SSL certificate issued (no browser warnings)
- ✅ Client appears in portal dropdown
- ✅ Credentials saved securely
- ✅ Company configured with UK settings
- ✅ Ready for wizard configuration (sections 2-16)

---

## 💡 Best Practices

### Security

1. **Change default passwords** after sharing with client
2. **Enable 2FA** for administrator accounts (Wizard Section 7)
3. **Restrict user permissions** to minimum required (Wizard Section 7)
4. **Regular backups**:
   ```bash
   docker exec erpnext-backend bench --site acme.byrne-accounts.org backup --with-files
   ```

### Data Management

1. **Complete wizard sections 1-10** before going live
2. **Import data in order**: Customers → Items → Opening Balances
3. **Test transactions** before real data (Wizard Section 16)
4. **Document customizations** for future reference

### Client Onboarding

1. **Send credentials** via secure channel (encrypted email, password manager)
2. **Schedule training session** to walk through system
3. **Provide quick reference**: Share `docs/ERPNEXT_QUICK_REFERENCE.md`
4. **Set expectations**: Initial setup takes 1-2 hours with wizard

---

## 🔄 Next Steps After Provisioning

### Immediate (First Hour)

1. ✅ Complete Wizard Sections 2-7 (Foundation)
2. ✅ Test basic transaction flow
3. ✅ Create 2-3 sample products/services
4. ✅ Create test customer and invoice

### First Day

1. ✅ Complete Wizard Sections 8-10 (Polish)
2. ✅ Import real customer data
3. ✅ Import real product catalog
4. ✅ Configure email notifications
5. ✅ Customize print formats
6. ✅ Apply branding

### First Week

1. ✅ Complete relevant advanced sections (11-16)
2. ✅ Train staff on system
3. ✅ Import historical data (if needed)
4. ✅ Set up automated workflows
5. ✅ Configure custom reports
6. ✅ Run comprehensive testing (Section 16)

### Ongoing

1. ✅ Regular backups (automated via cron)
2. ✅ Monitor system health
3. ✅ Review and refine workflows
4. ✅ Gather client feedback
5. ✅ Plan additional customizations

---

## 📊 Estimated Timeline

| Phase | Time | Sections |
|-------|------|----------|
| **Infrastructure Setup** | 5-10 min | Automated |
| **Initial Browser Wizard** | 2-3 min | Manual |
| **Foundation Setup** | 60-90 min | Wizard 2-7 |
| **Polish & Branding** | 30-45 min | Wizard 8-10 |
| **Advanced Features** | Variable | Wizard 11-16 |
| **Testing & Go-Live** | 30-45 min | Wizard 16 + Final checks |
| **TOTAL (Basic)** | 2-3 hours | Sections 1-10 |
| **TOTAL (Complete)** | 4-6 hours | All sections |

---

## ✨ Summary

The integrated provisioning + wizard system provides:

1. **Automated Infrastructure** - ERPNext, email, SSL, routing
2. **Guided Configuration** - 16-section interactive wizard
3. **Comprehensive Coverage** - Basic to advanced features
4. **Progress Tracking** - Resume anytime, mark sections complete
5. **Professional Result** - Fully configured, branded, production-ready system

**Ready to provision your first client!** 🚀

---

**Version**: 2.0
**Date**: November 1, 2025
**Maintainer**: SecureNexus Infrastructure Team
